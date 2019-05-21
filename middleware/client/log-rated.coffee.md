    @name = "astonishing-competition:middleware:client:log-rated"
    {debug,heal} = (require 'tangible') @name
    CouchDB = require 'most-couchdb'
    Nimble = require 'nimble-direction'
    moment = require 'moment'

    {Executor} = require '../../runner'
    build_commands = require '../commands'
    {get_ornaments} = require '../../get_ornaments'
    compile = require '../../compile'
    sleep = require 'marked-summer/sleep'
    sleep_until = (time) ->
      now = moment.utc()
      if time.isAfter now
        sleep time.diff now
    ec = encodeURIComponent
    {period_for,cdr_period_for,rated_carrier} = require '../../tools'

    seconds = 1000

    {prepare_client_cdr,prepare_carrier_cdr} = require '../../prepare'

Call handler
============

    @include = ->

      N = Nimble @cfg

      debug 'Start'

      LocalDB = (name) =>
        uri = "#{N.prefix_admin}/#{ec name}"
        db = new CouchDB uri, true
        await db.info().catch -> db.create()
        db

These are all preconditions. None of them should fail unless the proper modules are not loaded.
(In other words these all indicate developer errrors.)

      fail = =>
        await @respond '500 Unable to rate'
        @direction 'failed'

      unless @session?
        debug.dev 'No session'
        await fail()
        return

      unless @cfg.rating_plans?
        debug.dev 'No cfg.rating_plans'
        await fail()
        return

      PlansDB = new CouchDB @cfg.rating_plans

      unless @session.rated?
        debug.dev 'No session.rated'
        await fail()
        return

      unless @session.rated.params?
        debug.dev 'No session.rated.params'
        await fail()
        return

Remember, we expect to have:
- session.rated.client (might be missing)
- session.rated.carrier (might be missing)
- session.rated.params, esp session.rated.params.client and session.rated.params.carrier.

All databases are period-bound (typically, monthly).
The databases can be deleted after whatever time interval is convenient in terms of storage space and legal obligations.

End-of-call handler
===================

      debug 'Setting handle_final'

* cfg.CDR_DB_PREFIX (string) database-name prefix for CDRs. Default: `cdr`

      {CDR_DB_PREFIX} = @cfg
      CDR_DB_PREFIX ?= 'cdr'

This is executed only once, at the end of the call, to generate the CDR used for billing.
This CDR is saved in a database.

      handle_final = (cdr_report) =>
        duration = Math.ceil( parseInt(cdr_report.billable,10) / seconds )

        debug 'handle_final', duration

Handle the interface with tough-rate.

`tough-rate` will set `session.gateway` before placing the call out, and `session.winner` once the call is successfully _finished_.
However `session.winner` might be set _after_ we get called, depending on timing; so if it is present we use it; if it isn't, we assume the last gateway tried by tough-rate is the one we need to consider.

        params = @session.rated?.params
        params.carrier ?= @session.winner or @session.gateway

Rebuild @session.rated, similarly to what is done in ./rating

        debug 'Client  is ', params.client?._id
        debug 'Carrier is ', params.carrier?._id

        @session.rated = await @cfg.rating
          .rate params
          .catch (error) =>
            debug "rating_rate failed: #{error.stack ? error}"
            null

        @session.rated ?= {}
        @session.rated.params = params

For the client
--------------

        client_cdr = @session.rated.client
        if client_cdr?

          debug 'Preprocessing client', client_cdr
          account = @cfg.rated_account @session.rated

Counters are handled at the `sub_account` level (although we could also have `account`-level counters, I guess).

          sub_account = @cfg.rated_sub_account @session.rated
          client_period = period_for client_cdr
          counters_prefix = ['ω',sub_account,client_period].join ' '

          private_commands = build_commands.call this
          executor = new Executor counters_prefix, private_commands, @cfg.br

          plan_script = await get_ornaments PlansDB, client_cdr

          if plan_script?
            plan_fun = try compile plan_script, private_commands catch error
            unless plan_fun?
              debug.dev 'Invalid plan script (ignored)', error, plan_script
          plan_fun ?= ->

          debug 'handle_final: client', duration
          try
            client_cdr.compute duration
            cdr = client_cdr.toJS()

            await executor.run plan_fun, cdr

            cdr.processed = true

Period-database: (monthly) database used to globally generate invoices. Contains data for all accounts.

            client_cdr_period = cdr_period_for cdr
            client_database = [CDR_DB_PREFIX,client_cdr_period].join '-'

Do not store CDRs for calls that must be hidden (e.g. emergency calls in most jurisdictions).

            unless cdr.hide_call

              cdr = prepare_client_cdr cdr, account, sub_account
              debug "LocalDB(#{client_database}).put", cdr
              await (await LocalDB client_database).put cdr

          catch error
            debug.dev "safely_write client: #{error.stack ? JSON.stringify error}", client_database

For the carrier
---------------

A rated `carrier` object, saved into the rated-database for the carrier.

        carrier_cdr = @session.rated.carrier
        if carrier_cdr?

          debug 'handle_final: carrier', duration
          try
            carrier_cdr.compute duration
            cdr = carrier_cdr.toJS()

            carrier = rated_carrier @session.rated
            carrier_cdr_period = cdr_period_for cdr
            carrier_database = [CDR_DB_PREFIX,carrier,carrier_cdr_period].join '-'

            cdr = prepare_carrier_cdr cdr
            debug "LocalDB(#{carrier_database}).put", cdr
            await (await LocalDB carrier_database).put cdr

          catch error
            debug.dev "safely_write carrier: #{error.stack ? JSON.stringify error}", carrier_database

        debug 'rated:done'

Put the handler in service
--------------------------

Handle both the case where the call is over (sync)

      if @session.cdr_report?
        heal handle_final @session.cdr_report

or in-progress (async)

      else
        @once 'cdr_report', (report) ->
          heal handle_final report
          return

      debug 'Ready'
