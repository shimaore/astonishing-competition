    @name = "#{(require '../package').name}:middleware:log-rated"
    debug = (require 'debug') @name
    seem = require 'seem'
    fs = (require 'bluebird').promisifyAll require 'fs'
    path = require 'path'
    PouchDB = require 'shimaore-pouchdb'
    moment = require 'moment-timezone'
    assert = require 'assert'
    uuid = require 'uuid'

Save remotely by default, fallback to

    RemotePouchDB = null
    LocalPouchDB = null
    plans_db = null

    aggregate = require '../aggregation'

Compute period

    @server_pre = ->

* cfg.aggregation.remote (string,URI,required) base URI for remote invoicing databases

      if @cfg.aggregation?.remote?
        RemotePouchDB = PouchDB.defaults prefix: @cfg.aggregation.remote
      else
        debug 'Missing cfg.aggregation.remote'

* cfg.aggregation.local (string,path) directory where CDRs are stored if cfg.aggregation.remote fails. The directory must be present.

      if @cfg.aggregation?.local?
        LocalPouchDB = PouchDB.defaults prefix: @cfg.aggregation.local
      else
        debug 'Missing cfg.aggregation.local'

      if @cfg.aggregation?.plans?
        plans_db = new PouchDB @cfg.aggregation.plans
      else
        debug 'Missing cfg.aggregation.plans'

* cfg.period_of (function) convert a timestamp into a billing period. Default: 'YYYY-MM' monthly period based on timestamp as UTC.

      @cfg.period_of ?= (stamp,timezone = 'UTC') ->
        moment
        .tz stamp, timezone
        .format 'YYYY-MM'

* cfg.period_for (function, optional) maps a rated.client or rated.carrier into a period. Default: use cfg.period_of on the connection timestamp and timezone.

      @cfg.period_for ?= (side) =>
        return unless side?
        side.period = @cfg.period_of side.connect_stamp, side.timezone

* cfg.period_for_client (function) computes a client-side period based on a rated CDR. Default: use cfg.period_for on the rated.client record.

      @cfg.period_for_client ?= (rated) =>
        @cfg.period_for rated.client

* cfg.period_for_carrier (function) computes a carrier-side period based on a rated CDR. Default: use cfg.period_for on the rated.carrier record.

      @cfg.period_for_carrier ?= (rated) =>
        @cfg.period_for rated.carrier

* cfg.rated_sub_account (function) computes a sub-account unique identifier based on a rated CDR. Default: use rated.params.client.account and rated.params.client.sub_account.

      @cfg.rated_sub_account ?= (rated) ->
        p = rated.params.client
        switch
          when p?.account? and p?.sub_account?
            [p.account,p.sub_account].join '_'
          when p?.account?
            p.account
          else
            'unknown-client'

* cfg.rated_account (function) computes an account unique identifier based on a rated CDR. Default: use rated.params.client.account.

      @cfg.rated_account ?= (rated) ->
        p = rated.params.client
        switch
          when p?.account?
            p.account
          else
            'unknown-client'

* cfg.rated_carrier (function) computes a carrier unique identifier based on a rated CDR. Default: use rated.params.carrier.carrier.

      @cfg.rated_carrier ?= (rated) ->
        rated.params.carrier?.carrier ? 'unknown-carrier'

* cfg.CDR_DB_PREFIX (string) database-name prefix for CDRs. Default: `cdr`

      @cfg.CDR_DB_PREFIX ?= 'cdr'

* cfg.TRACE_DB_PREFIX (string) database-name prefix for traces. Default: `trace`

      @cfg.TRACE_DB_PREFIX ?= 'trace'

Safely-write
------------

Try remote database, local database, and local file.

* cfg.safely_write (function) save data in a database, try remote database, local database, and local file.

      @cfg.safely_write = seem (database,data) ->
        data.database = database
        return unless RemotePouchDB?

        debug 'try remote db', database, data._id
        remote_db = new RemotePouchDB database

        try
          yield remote_db.put data

        catch error
          safely_write_local database, data

        yield remote_db
          .close()
          .catch (error) ->
            debug "remote db close #{error.stack ? error}"
            null

        remote_db = null

Safely-write, local database
----------------------------

      safely_write_local = seem (database,data) ->
        data.database = database
        return unless LocalPouchDB?

        debug 'try local db', database
        local_db = new LocalPouchDB database

        try
          yield local_db.put data

FIXME sync from local_db to remote_db in the background to ensure our local records eventually make it to the server
FIXME purge local_db so that it doesn't just grow in size indefinitely

        catch error
          safely_write_file database, data

FIXME upload locally-saved JSON files to remote-db

        yield local_db
          .close()
          .catch (error) ->
            debug "local db close: #{error.stack ? error}"
            null

        local_db = null

Safely-write, local file
------------------------

      safely_write_file = seem (database,data) =>
        data.database = database
        return unless @cfg.aggregation?.local?

        filename = path.join @cfg.aggregation.local, "#{uuid.v4()}.json"
        debug 'save as JSON', filename
        yield fs.writeFileAsync filename, JSON.stringify(data), 'utf-8'

      null

Call handler
============

    @include = ->

Prevent calls from going through if we won't be able to rate / save them.

      unless plans_db and (RemotePouchDB? or LocalPouchDB?)
        unless @cfg.route_non_billable_calls
          debug 'Unable to rate'
          @respond '500 Unable to rate'
        return

The `rated` event generated by earthy-slave/middleware/rated is our trigger.

      @call.on 'rated', seem (rated) =>

FIXME: do `rated_account`, `rated_sub_account` etc. early on in the call, so that the code can detect unbillable calls earlier. This would also allow prepaid to work properly.

        debug 'rated'

We need to figure out:
- where we want to log: which databases (two for client side, one for carrier side, one for traces)
- how we want to log it: what document identifier

We assume that invoices are generated at the `account` level.

        account = @cfg.rated_account rated

And that counters are handled at the `sub_account` level (although we could also have `account`-level counters, I guess).

        sub_account = @cfg.rated_sub_account rated

        carrier = @cfg.rated_carrier rated

Periods are defined for client and carrier CDRs.

        client_period = @cfg.period_for_client rated
        carrier_period = @cfg.period_for_carrier rated

All databases are period-bound (typically, monthly).
The databases can be deleted after whatever time interval is convenient in terms of storage space and legal obligations.

We're saving three objects per call, in four different databases.

Client object
-------------

A rated and aggregated `client` object, used for billing, saved into the rated-databases.

        if rated.client?

Period-database: (monthly) database used to globally generate invoices. Contains data for all accounts.

          period_database = [@cfg.CDR_DB_PREFIX,client_period].join '-'
          period_db = new RemotePouchDB period_database

Account-database: (monthly) client-accessible database used to store CDRs accessible by the client.

          account_database = [@cfg.CDR_DB_PREFIX,account,client_period].join '-'

Counters at the sub-account level.

          counters_id = ['counters',sub_account,client_period].join '-'

          try
            yield period_db
              .put _id: counters_id
              .catch -> yes

            cdr = yield aggregate.rate plans_db, period_db, counters_id, rated.client

            cdr.trace_id = @session._id

            if cdr?
              cdr.processed = true
            else
              debug 'CDR could not be processed.'

FIXME: cuddly

              cdr = rated.client
              cdr.processed = false

Do not store CDRs for calls that must be hidden (e.g. emergency calls in most jurisdictions).

            unless cdr.hide_call

              yield @cfg.safely_write period_database, cdr

              public_cdr =
                _id: cdr._id
                direction: cdr.direction
                to: cdr.to
                from: cdr.from
                stamp: cdr.stamp
                timezone: cdr.timezone
                destination: cdr.destination
                duration: cdr.duration
                processed: cdr.processed
                currency: cdr.currency
                actual_amount: cdr.actual_amount

              yield @cfg.safely_write account_database, public_cdr

          catch error
            debug "safely_write client: #{error.stack ? error}", period_database, account_database,

          yield period_db
            .close()
            .catch (error) ->
              debug "billing db close: #{error.stack ? error}"
              null

          period_db = null

Carrier object
--------------

A rated `carrier` object, saved into the rated-database for the carrier.

        if rated.carrier?

          carrier_database = [@cfg.CDR_DB_PREFIX,carrier,carrier_period].join '-'

          cdr = rated.carrier
          cdr.trace_id = @session._id

          try
            yield @cfg.safely_write carrier_database, cdr
          catch error
            debug "safely_write carrier: #{error.stack ? error}", carrier_database

Trace object
------------

The entire `@session` object, used for troubleshooting, saved into the trace-database
(this includes the session.data object set in tough-rate and others)

        trace_period = client_period
        trace_period ?= @cfg.period_of rated.params.stamp, rated.params.client?.timezone

        trace_database = [@cfg.TRACE_DB_PREFIX,trace_period].join '-'
        try

          trace_data = {}
          for own k,v of @session when typeof v isnt 'function'
            trace_data[k] = v
          yield @cfg.safely_write trace_database, trace_data
        catch error
          debug 'safely_write trace', trace_database, error.stack ? error

        debug 'rated:done'

      debug 'Ready'
