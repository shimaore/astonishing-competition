    @name = "#{(require '../package').name}:middleware:log-rated"
    {debug,hand,heal} = (require 'tangible') @name
    seem = require 'seem'
    fs = (require 'bluebird').promisifyAll require 'fs'
    path = require 'path'
    PouchDB = require 'shimaore-pouchdb-core'
      .plugin require 'pouchdb-adapter-http'
    LRU = require 'lru-cache'
    moment = require 'moment'
    assert = require 'assert'
    uuid = require 'uuid'

Save remotely by default, fallback to

    RemotePouchDB = null
    LocalPouchDB = null
    plans_db = null

    cache = LRU
      max: 12
      dispose: (key,value) ->
        debug 'Dispose of', key
        value?.close?()

    Aggregator = require '../aggregation'
    Runner = require '../runner'
    {conditions} = require '../commands'
    sleep = require 'marked-summer/sleep'
    sleep_until = (time) ->
      now = moment.utc()
      if time.isAfter now
        sleep time.diff now

    seconds = 1000

Compute period

    @server_pre = ->

* cfg.aggregation.remote (string,URI,required) base URI for remote invoicing databases

      if @cfg.aggregation?.remote?
        RemotePouchDB = (name) =>
          cache_name = "RemotePouchDB #{name}"
          db = cache.get cache_name
          return db if db?
          db = new PouchDB name, prefix: @cfg.aggregation.remote
          cache.set cache_name, db
          db

      else
        debug 'Missing cfg.aggregation.remote'

* cfg.aggregation.local (string,path) directory where CDRs are stored if cfg.aggregation.remote fails. The directory must be present.

      if @cfg.aggregation?.local?
        LocalPouchDB = (name) =>
          cache_name = "LocalPouchDB #{name}"
          db = cache.get cache_name
          return db if db?
          db = new PouchDB name, prefix: @cfg.aggregation.local
          cache.set cache_name, db
          db

      else
        debug 'Missing cfg.aggregation.local'

      if @cfg.aggregation?.plans?
        plans_db = new PouchDB @cfg.aggregation.plans
      else
        debug 'Missing cfg.aggregation.plans'

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

      @cfg.safely_write ?= seem (database,data) ->
        data.database = database
        return unless RemotePouchDB?

        debug 'try remote db', database, data._id
        remote_db = RemotePouchDB database

        try
          yield remote_db.put data

        catch error
          safely_write_local database, data

        remote_db = null

Safely-write, local database
----------------------------

      safely_write_local = seem (database,data) ->
        data.database = database
        return unless LocalPouchDB?

        debug 'try local db', database
        local_db = LocalPouchDB database

        try
          yield local_db.put data

FIXME sync from local_db to remote_db in the background to ensure our local records eventually make it to the server
FIXME purge local_db so that it doesn't just grow in size indefinitely

        catch error
          safely_write_file database, data

FIXME upload locally-saved JSON files to remote-db

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

    @include = seem ->

      @debug 'Start'

Prevent calls from going through if we won't be able to rate / save them.

      unless plans_db and (RemotePouchDB? or LocalPouchDB?)
        unless @cfg.route_non_billable_calls
          @debug 'Unable to rate, no plans_db or Remote/Local PouchDB'
          yield @respond '500 Unable to rate'
          @direction 'failed'
        return

      unless @session.rated?
        @debug 'No session.rated'
        yield @respond '500 Unable to rate'
        @direction 'failed'
        return

      unless @session.rated.params?
        @debug 'No session.rated.params'
        yield @respond '500 Unable to rate'
        @direction 'failed'
        return

Remember, we expect to have:
- session.rated.client (might be missing)
- session.rated.carrier (might be missing)
- session.rated.params, esp session.rated.params.client and session.rated.params.carrier.

We need to figure out:
- where we want to log: which databases (two for client side, one for carrier side, one for traces)
- how we want to log it: what document identifier

All databases are period-bound (typically, monthly).
The databases can be deleted after whatever time interval is convenient in terms of storage space and legal obligations.

We're saving three objects per call, in four different databases.

Client object
-------------

A rated and aggregated `client` object, used for billing, saved into the rated-databases.

### Before the call starts.

      if @session.rated.client?

        @debug 'Preprocessing client'

We assume that invoices are generated at the `account` level.

        account = @cfg.rated_account @session.rated

And that counters are handled at the `sub_account` level (although we could also have `account`-level counters, I guess).

        sub_account = @cfg.rated_sub_account @session.rated

        client_period = @cfg.period_for_client @session.rated

Period-database: (monthly) database used to globally generate invoices. Contains data for all accounts.

        period_database = [@cfg.CDR_DB_PREFIX,client_period].join '-'
        period_db = RemotePouchDB period_database

Counters at the sub-account level.

        counters_id = ['counters',sub_account,client_period].join '-'

        yield period_db
          .put _id: counters_id
          .catch -> yes

        client_aggregator = new Aggregator plans_db, period_db, counters_id, @session.rated.client

      else

        @debug 'No session.rated.client'

Compute and save CDR
====================

      debug 'Setting handle_final'

      handle_final = seem (cdr_report) =>
        duration = Math.ceil( parseInt(cdr_report.billable,10) / seconds )

        debug 'handle_final', duration

        if client_execute?
          yield client_execute duration
            .catch (error) =>
              debug "client_execute: #{error.stack ? error}"

For the client
--------------

        if client_aggregator?

          debug 'handle_final: client'
          try

            cdr = yield client_aggregator.handle duration

            if cdr?
              cdr.processed = true
            else
              debug 'CDR could not be processed.'

              cdr = @session.rated.client?.toJSON() ? {}
              cdr.processed = false

            cdr.trace_id = @session._id

Do not store CDRs for calls that must be hidden (e.g. emergency calls in most jurisdictions).

            unless cdr.hide_call

              yield @cfg.safely_write period_database, cdr

          catch error
            debug "safely_write client: #{error.stack ? error}", period_database

Carrier object
--------------

A rated `carrier` object, saved into the rated-database for the carrier.

        if @session.rated.carrier?

          debug 'handle_final: carrier'

          carrier = @cfg.rated_carrier @session.rated
          carrier_period = @cfg.period_for_carrier @session.rated
          carrier_database = [@cfg.CDR_DB_PREFIX,carrier,carrier_period].join '-'

          @session.rated.carrier.compute duration
          cdr = @session.rated.carrier.toJSON()
          cdr.trace_id = @session._id

          try
            yield @cfg.safely_write carrier_database, cdr
          catch error
            debug "safely_write carrier: #{error.stack ? error}", carrier_database

        debug 'rated:done'

Put the CDR and trace in service
--------------------------------

Handle both the case where the call is over (sync)

      if @session.cdr_report?
        heal handle_final @session.cdr_report

or in-progress (async)

      else
        @once 'cdr_report', (report) ->
          heal handle_final report
          return

      debug 'Ready'

Rating ornament
---------------

* doc.endpoint.rating_ornaments (ornaments) used to decide whether the call can proceed. Uses commands from astonishing-competition/commands.conditions: `at_most(maximum,counter)`, `called_mobile`, `called_fixed`, `called_fixed_or_mobile`, `called_country(countries|country)`, `called_emergency`, `called_onnet`, `up_to(total,counter)`, `free`, `hangup`.

      ornaments = @session.rated.params.client?.rating_ornaments
      if ornaments?
        @debug 'Processing rating ornaments.'

        if not client_aggregator?
          @debug.csr 'No aggregator available.'
          yield @respond '500 no aggregator available'
          @direction 'failed'
          return

        for own k,v of conditions
          @ornaments_commands[k] = v

        client_runner = new Runner period_db, counters_id, @ornaments_commands
        client_runner.ornaments = ->
          ornaments

        runner_cdr = {}

Execute the call decision script at the given duration point.

        client_execute = seem (duration) =>

          debug 'client_execute', duration

First compute the CDR at that time point.

          cdr = yield client_aggregator.handle duration
          for own k,v of cdr
            runner_cdr[k] = v

Note: not all ornament-commands (especially the ones defined in huge-play) are applicable to all calls.

Next, evaluate the client decision code as well.

          client_runner.context = (cdr,counters) =>
            @cdr = cdr
            @counters = counters
            this

          yield client_runner.run runner_cdr

          delete @cdr
          delete @counters

          debug 'client_execute completed', duration

        initial_duration = @session.rated.client?.rating_data?.initial?.duration
        if not initial_duration? or initial_duration is 0
          initial_duration = @session.rated.client?.rating_data?.subsequent?.duration

        if not initial_duration?
          @debug.csr 'No initial duration available'
          yield @respond '500 no initial duration available'
          @direction 'failed'
          return

* doc.endpoint.rating_inverval (integer) Interval at which to re-evaluate the call for continuation. Defaults: cfg.rating_interval, 20s otherwise.

        interval = @session.rated.params.client?.rating_interval
        interval ?= @cfg.rating_interval
        interval ?= 20

Execute the script a first time when the call is routing / in-progress.

        yield client_execute initial_duration

Then, once the call is answered:

        running = false

        yield @call.event_json 'CHANNEL_ANSWER', 'CHANNEL_HANGUP_COMPLETE'

        @call.once 'CHANNEL_ANSWER', hand =>
          debug 'CHANNEL_ANSWER'
          running = true
          start_time = moment.utc()

- Execute the script a second time at the time the call is actually answered (things might have changed while the call was making progress and/or being routed).

          end_of_interval = initial_duration
          yield client_execute end_of_interval

- After that, do a first check at the end of the initial-duration, then once for every interval.

          yield sleep_until start_time.clone().add seconds: end_of_interval

          while running

Note: we always compute the conditions at the _end_ of the _upcoming_ interval, and we do not start an interval that would result in a rejection.
(In other words, we attempt to maintain the invariant implemented by `rating_ornaments`.)

            end_of_interval += interval
            yield client_execute end_of_interval
            yield sleep_until start_time.clone().add seconds: end_of_interval

          period_db = null

          debug 'Call was hung up'

        @call.once 'CHANNEL_HANGUP_COMPLETE', =>
          debug 'CHANNEL_HANGUP_COMPLETE'
          running = false

        @debug 'Rating ornament is ready.'
        return

      return

FIXME: How does this work for transferred calls? (There is a FreeSwitch flag to prevent transfers, I seem to remember.)
