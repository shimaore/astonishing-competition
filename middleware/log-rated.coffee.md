    @name = "#{(require '../package').name}:middleware:log-rated"
    debug = (require 'debug') @name
    seem = require 'seem'
    fs = (require 'bluebird').promisifyAll require 'fs'
    path = require 'path'
    PouchDB = require 'pouchdb'
    moment = require 'moment-timezone'
    assert = require 'assert'
    uuid = require 'uuid'

Save remotely by default, fallback to

    RemotePouchDB = null
    LocalPouchDB = null
    plans_db = null

    CDR_DB_PREFIX = 'cdr'
    TRACE_DB_PREFIX = 'trace'

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

      @cfg.period_for ?= (side) =>
        return unless side?
        side.period = @cfg.period_of side.connect_stamp, side.timezone

      @cfg.period_of ?= (stamp,timezone = 'UTC') ->
        moment
        .tz stamp, timezone
        .format 'YYYY-MM'

Safely-write
------------

Try remote database, local database, and local file.

      @cfg.safely_write = seem (database,data) ->
        data.database = database
        return unless RemotePouchDB?

        debug 'try remote db', database
        remote_db = new RemotePouchDB database

        try
          yield remote_db.put data

        catch error
          safely_write_local database, data

        finally
          remote_db.close()

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

        finally
          local_db.close()

Safely-write, local file
------------------------

      safely_write_file = seem (database,data) =>
        data.database = database
        return unless @cfg.aggregation?.local?

        filename = path.join @cfg.aggregation.local, "#{uuid.v4()}.json"
        debug 'save as JSON', filename
        yield fs.writeFileAsync filename, JSON.stringify(data), 'utf-8'

      null

    @include = ->

      unless plans_db and (RemotePouchDB? or LocalPouchDB?)
        unless @cfg.route_non_billable_calls
          debug 'Unable to rate'
          @respond '500 Unable to rate'
        return

      @call.on 'rated', seem (rated) =>

        debug 'rated'

We need to figure out:
- where we want to log: which databases (one for client side, one for carrier side)
- how we want to log it: what document identifier

        client = rated.params.client?.account ? 'unknown-client'
        carrier = rated.params.carrier?.carrier ? 'unknown-carrier'

        client_period = @cfg.period_for rated.client
        carrier_period = @cfg.period_for rated.carrier

We're saving three objects:

- a rated and aggregated `client` object, used for billing, into the rated-database

        if rated.client?
          client_database = [CDR_DB_PREFIX,client,client_period].join '-'
          billing_db = new RemotePouchDB client_database

          try
            yield billing_db
              .put _id:'counters'
              .catch -> yes

            yield aggregate.rate plans_db, billing_db, rated.client
            unless rated.client.hide_call
              yield @cfg.safely_write client_database, rated.client
          catch error
            debug 'safely_write client_database', error.stack ? error
          finally
            yield billing_db.close()
            billing_db = null

- a rated `carrier` object, into the rated-database for the carrier.

        if rated.carrier?
          carrier_database = [CDR_DB_PREFIX,carrier,carrier_period].join '-'
          try
            yield @cfg.safely_write carrier_database, rated.carrier
          catch error
            debug 'safely_write carrier_database', error.stack ? error

- the entire `@session` object, used for troubleshooting, into the trace-database
  (this includes the session.data object set in tough-rate and others)

  The trace-databases can be deleted after whatever period is convenient in terms
  of storage space and legal obligations.

        trace_period = client_period
        trace_period ?= @cfg.period_of rated.params.stamp, rated.params.client?.timezone

        trace_database = [TRACE_DB_PREFIX,client,trace_period].join '-'
        try

Compute an ID similar to the one in entertaining-crib/rated,
except we don't have the same data available.

          @session._id = [
            @source
            @session.rated.params.stamp
            @destination
            @session.cdr_report.duration
          ].join '-'

          trace_data = {}
          for own k,v of @session when typeof v isnt 'function'
            trace_data[k] = v
          yield @cfg.safely_write trace_database, trace_data
        catch error
          debug 'safely_write trace_database', error.stack ? error

        debug 'rated:done'

      debug 'Ready'
