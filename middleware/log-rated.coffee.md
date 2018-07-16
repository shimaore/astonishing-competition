    @name = "#{(require '../package').name}:middleware:log-rated"
    {debug,hand,heal} = (require 'tangible') @name
    fs = (require 'bluebird').promisifyAll require 'fs'
    path = require 'path'
    PouchDB = require 'ccnq4-pouchdb'
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

    {Executor,Runner} = require '../runner'
    {rate} = require '../commands'
    {get_ornaments} = require '../get_ornaments'
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
            'unknown-account'

* cfg.rated_account (function) computes an account unique identifier based on a rated CDR. Default: use rated.params.client.account.

      @cfg.rated_account ?= (rated) ->
        p = rated.params.client
        switch
          when p?.account?
            p.account
          else
            'unknown-account'

* cfg.rated_carrier (function) computes a carrier unique identifier based on a rated CDR. Default: use rated.params.carrier.carrier.

      @cfg.rated_carrier ?= (rated) ->
        rated.params.carrier?.carrier ? 'unknown-carrier'

* cfg.CDR_DB_PREFIX (string) database-name prefix for CDRs. Default: `cdr`

      @cfg.CDR_DB_PREFIX ?= 'cdr'

Safely-write
------------

Try remote database, local database, and local file.

* cfg.safely_write (function) save data in a database, try remote database, local database, and local file.

      @cfg.safely_write ?= (database,data) ->
        data.database = database
        return unless RemotePouchDB?

        debug 'try remote db', database, data._id
        remote_db = RemotePouchDB database

        try
          await remote_db.put data

        catch error
          safely_write_local database, data

        remote_db = null

Safely-write, local database
----------------------------

      safely_write_local = (database,data) ->
        data.database = database
        return unless LocalPouchDB?

        debug 'try local db', database
        local_db = LocalPouchDB database

        try
          await local_db.put data

FIXME sync from local_db to remote_db in the background to ensure our local records eventually make it to the server
FIXME purge local_db so that it doesn't just grow in size indefinitely

        catch error
          safely_write_file database, data

FIXME upload locally-saved JSON files to remote-db

        local_db = null

Safely-write, local file
------------------------

      safely_write_file = (database,data) =>
        data.database = database
        return unless @cfg.aggregation?.local?

        filename = path.join @cfg.aggregation.local, "#{uuid.v4()}.json"
        debug 'save as JSON', filename
        await fs.writeFileAsync filename, JSON.stringify(data), 'utf-8'

      null

Call handler
============

    @include = ->

      @debug 'Start'

      unless @session?
        heal @action 'respond', '500 No session, unable to rate'
        return

Prevent calls from going through if we won't be able to rate / save them.

      unless plans_db and (RemotePouchDB? or LocalPouchDB?)
        unless @cfg.route_non_billable_calls
          @debug 'Unable to rate, no plans_db or Remote/Local PouchDB'
          await @respond '500 Unable to rate'
          @direction 'failed'
        return

      unless @session.rated?
        @debug 'No session.rated'
        await @respond '500 Unable to rate'
        @direction 'failed'
        return

      unless @session.rated.params?
        @debug 'No session.rated.params'
        await @respond '500 Unable to rate'
        @direction 'failed'
        return

Remember, we expect to have:
- session.rated.client (might be missing)
- session.rated.carrier (might be missing)
- session.rated.params, esp session.rated.params.client and session.rated.params.carrier.

We need to figure out:
- where we want to log: which databases (two for client side, one for carrier side)
- how we want to log it: what document identifier

All databases are period-bound (typically, monthly).
The databases can be deleted after whatever time interval is convenient in terms of storage space and legal obligations.

We're saving three objects per call, in four different databases.

Client setup
------------

A rated and aggregated `client` object, used for billing, saved into the rated-databases.

### Before the call starts.

      client_cdr = @session.rated.client

      if client_cdr?

        @debug 'Preprocessing client', client_cdr

        plan_ornaments = await get_ornaments plans_db, client_cdr

We assume that invoices are generated at the `account` level.

        account = @cfg.rated_account @session.rated

And that counters are handled at the `sub_account` level (although we could also have `account`-level counters, I guess).

        sub_account = @cfg.rated_sub_account @session.rated

        client_period = @cfg.period_for_client @session.rated

Period-database: (monthly) database used to globally generate invoices. Contains data for all accounts.

        client_database = [@cfg.CDR_DB_PREFIX,client_period].join '-'

Counters at the sub-account level.

        counters_prefix = ['counters',sub_account,client_period].join ' '

        client_executor = new Executor counters_prefix, rate
        client_runner = new Runner client_executor, blue_ring

      else

        @debug 'No session.rated.client'

Compute and save CDR
====================

      debug 'Setting handle_final'

This is executed only once, at the end of the call, to generate the CDR used for billing.
This CDR is saved in a database.

      handle_final = (cdr_report) =>
        duration = Math.ceil( parseInt(cdr_report.billable,10) / seconds )

        debug 'handle_final', duration

        await incall_execute? duration
          .catch (error) =>
            debug "incall_execute: #{error.stack ? error}"

For the client
--------------

        if client_runner?

          debug 'handle_final: client'
          try

            cdr = await client_runner.evaluate plan_ornaments, client_cdr, duration

            if cdr?
              cdr.processed = true
            else
              debug 'CDR could not be processed.'

              cdr = client_cdr?.toJSON() ? {}
              cdr.processed = false

            cdr.trace_id = @session._id

Do not store CDRs for calls that must be hidden (e.g. emergency calls in most jurisdictions).

            unless cdr.hide_call

              await @cfg.safely_write client_database, cdr

          catch error
            debug "safely_write client: #{error.stack ? error}", client_database

For the carrier
---------------

A rated `carrier` object, saved into the rated-database for the carrier.

        carrier_cdr = @session.rated.carrier
        if carrier_cdr?

          debug 'handle_final: carrier'

          carrier = @cfg.rated_carrier @session.rated
          carrier_period = @cfg.period_for_carrier @session.rated
          carrier_database = [@cfg.CDR_DB_PREFIX,carrier,carrier_period].join '-'

          carrier_cdr.compute duration
          cdr = carrier_cdr.toJSON()
          cdr.trace_id = @session._id

          try
            await @cfg.safely_write carrier_database, cdr
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
===============

Ornaments might be set on the endpoint to add decisions as to whether the call should proceed or not, or be interrupted at some point.

* doc.endpoint.rating_ornaments (ornaments) used to decide whether the call can proceed. Uses commands from astonishing-competition/commands.conditions: `at_most(maximum,counter)`, `called_mobile`, `called_fixed`, `called_fixed_or_mobile`, `called_country(countries|country)`, `called_emergency`, `called_onnet`, `up_to(total,counter)`, `free`, `hangup`.

      private_ornaments = @session.rated.params.client?.rating_ornaments
      if private_ornaments?
        @debug 'Processing (private) rating ornaments.'

        if not client_runner?
          @debug.csr 'No aggregator available.'
          await @respond '500 no aggregator available'
          @direction 'failed'
          return

        extra_commands =
          hangup: =>
            await @respond '402 rating limit'
            await @action 'hangup', '402 rating limit'
            @direction 'rejected'
            'over'

Private changes are saved in the counters, but do not update the "official" counters (i.e. those used for billing).
This allows customer code to maintain their own counters, without interfering with billing.

        private_executor = new Executor "_P_ #{counters_prefix}", Object.assign extra_commands, rate
        private_runner = new Runner private_executor, blue_ring

The client's rating-ornaments (defined in the endpoint) are executed multiple times during the call.

### Definition

        private_cdr = {}

        incall_execute = (duration) ->

          debug 'incall_execute', duration

Compute the CDR at that point in time.

          incall_cdr = await private_runner.evaluate plan_ornaments, client_cdr, duration

Then execute the client decision code.

          Object.assign private_cdr, incall_cdr
          await private_runner.run private_ornaments, private_cdr, duration

          debug 'incall_execute completed', duration
          return

### Execution

* doc.endpoint.rating_inverval (integer) Interval at which to re-evaluate the call for continuation. Default: cfg.rating_interval, 20s otherwise.
* cfg.rating_inverval (integer) The default value for doc.endpoint.rating_interval. Default: 20s.

        interval = @session.rated.params.client?.rating_interval
        interval ?= @cfg.rating_interval
        interval ?= 20

Execute the script a first time when the call is routing / in-progress.

        initial_duration = client_cdr?.rating_data?.initial?.duration
        if not initial_duration? or initial_duration is 0
          initial_duration = client_cdr?.rating_data?.subsequent?.duration

        if not initial_duration?
          @debug.csr 'No initial duration available'
          await @respond '500 no initial duration available'
          @direction 'failed'
          return

        await incall_execute initial_duration

Aterwards, we wait for the call to be answered.

        running = false

        await @call.event_json 'CHANNEL_ANSWER', 'CHANNEL_HANGUP_COMPLETE'

        on_answer = hand =>
          debug 'CHANNEL_ANSWER'
          running = true
          start_time = moment.utc()

- Execute the script a second time at the time the call is actually answered (things might have changed while the call was making progress and/or being routed).

          end_of_interval = initial_duration
          await incall_execute end_of_interval

- After that, do a first check at the end of the initial-duration period,

          await sleep_until start_time.clone().add seconds: end_of_interval

then once for every rating interval.

          while running

Note: we always compute the conditions at the _end_ of the _upcoming_ interval, and we do not start an interval that would result in a rejection.
(In other words, we attempt to maintain the invariant implemented by `rating_ornaments`.)

            end_of_interval += interval
            await incall_execute end_of_interval
            await sleep_until start_time.clone().add seconds: end_of_interval

          debug 'Call was hung up'

        @call.once 'CHANNEL_ANSWER', on_answer

        @call.once 'CHANNEL_HANGUP_COMPLETE', =>
          debug 'CHANNEL_HANGUP_COMPLETE'
          @call.removeListener 'CHANNEL_ANSWER', on_answer
          running = false

        @debug '(Private) rating ornament is ready.'

      return

FIXME: How does this work for transferred calls? (There is a FreeSwitch flag to prevent transfers, I seem to remember.)
