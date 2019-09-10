    @name = "astonishing-competition:middleware:in-call"
    {debug,foot,heal} = (require 'tangible') @name
    CouchDB = require 'most-couchdb'
    moment = require 'moment'

    {Executor} = require '../runner'
    build_commands = require './commands'
    {get_plan_fun} = require '../get_plan_fun'
    compile = require '../compile'
    sleep = require 'marked-summer/sleep'
    sleep_until = (time) ->
      now = moment.utc()
      if time.isAfter now
        sleep time.diff now

    {period_for} = require '../tools'

    seconds = 1000

Call handler
============

    @include = ->

      debug 'Start'

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

      unless @cfg.br?
        debug.dev 'No cfg.br'
        await fail()
        return

Remember, we expect to have:
- session.rated.client (might be missing)
- session.rated.params, esp session.rated.params.client

Client setup
------------

### Before the call starts.

      client_cdr = @session.rated.client

      unless client_cdr?
        debug 'No session.rated.client'
        return

Rating script
-------------

      debug 'Preprocessing client', client_cdr

Ornaments might be set on the endpoint (client-side) to add decisions as to whether the call should proceed or not, or be interrupted at some point.

* doc.endpoint.incall_script used to decide whether the call can proceed. Uses commands from astonishing-competition/commands.conditions: `at_most(maximum,counter)`, `called_mobile`, `called_fixed`, `called_fixed_or_mobile`, `called_country(countries|country)`, `called_emergency`, `called_onnet`, `up_to(total,counter)`, `free`, `hangup`.
* doc.endpoint.incall_values (hash) used in doc.endpoint.incall code as parameters; for example it is used by the `at_most_value` function to take decisions based on endpoint-specific parameters (for example to set a per-endpoint maximum amount of money to spend per billing period).

      endpoint = @session.rated.params.client
      private_script = endpoint?.incall_script
      private_script ?= endpoint?.rating_ornaments # legacy

      unless private_script?
        debug 'No private script'
        return

      debug 'Processing (private) in-call script.'

      private_commands = build_commands.call this

      plan_fun = await get_plan_fun PlansDB, client_cdr, compile, private_commands
      plan_fun ?= ->

      private_fun = try compile private_script, private_commands catch error
      unless private_fun?
        debug.dev 'Invalid private script (ignored)', error, private_script
      private_fun ?= ->

Private changes are saved in the counters, but do not update the "official" counters (i.e. those used for billing).
This allows customer code to maintain their own counters, without interfering with billing.

Counters are handled at the `sub_account` level (although we could also have `account`-level counters, I guess).

      sub_account = @cfg.rated_sub_account @session.rated
      client_period = period_for @session.rated.client
      counters_prefix = ['α',sub_account,client_period].join ' '
      executor = new Executor counters_prefix, private_commands, @cfg.br

### Definition

      private_cdr = {}

      incall_execute = (duration) ->

        debug 'incall_execute', duration

Compute the CDR at that point in time.

        incall_cdr = await executor.evaluate plan_fun, client_cdr, duration

Then execute the decision code on the updated CDR.

Notice that in most cases, the `plan` should hide emergency calls, meaning that the in-call scripts will not be executed for emergency calls.

        unless incall_cdr.hide_call
          Object.assign private_cdr, incall_cdr
          await executor.run private_fun, private_cdr

        debug 'incall_execute completed', duration
        return

### Execution

* doc.endpoint.incall_inverval (integer) Interval at which to re-evaluate the call for continuation. Default: cfg.incall_interval, 20s otherwise.
* cfg.incall_inverval (integer) The default value for doc.endpoint.incall_interval. Default: 20s.

      interval = @session.rated.params.client?.incall_interval
      interval ?= @cfg.incall_interval
      interval ?= 20

Execute the script a first time when the call is routing / in-progress.

      initial_duration = client_cdr?.rating_data?.initial?.duration
      if not initial_duration? or initial_duration is 0
        initial_duration = client_cdr?.rating_data?.subsequent?.duration

      if not initial_duration?
        debug.csr 'No initial duration available'
        await @respond '500 no initial duration available'
        @direction 'failed'
        return

`tough-rate` might calls us once the call is going to route

      @session.incall_script = ->
        await incall_execute initial_duration

      await incall_execute initial_duration

Aterwards, we wait for the call to be answered.

      running = false

      await @call.event_json 'CHANNEL_ANSWER', 'CHANNEL_HANGUP_COMPLETE'

      on_answer = foot =>
        debug 'CHANNEL_ANSWER'
        running = true
        start_time = moment.utc()

- Execute the script a second time at the time the call is actually answered (things might have changed while the call was making progress and/or being routed).

        end_of_interval = initial_duration
        await incall_execute end_of_interval

- After that, do a first check at the end of the initial-duration period,

        await sleep_until start_time.clone().add seconds: end_of_interval

then once for every interval.

        while running

Note: we always compute the conditions at the _end_ of the _upcoming_ interval, and we do not start an interval that would result in a rejection.
(In other words, we attempt to maintain the invariant implemented by `incall_script`.)

          end_of_interval += interval
          await incall_execute end_of_interval
          await sleep_until start_time.clone().add seconds: end_of_interval

        debug 'Call was hung up'

      @call.once 'CHANNEL_ANSWER', on_answer

      @call.once 'CHANNEL_HANGUP_COMPLETE', =>
        debug 'CHANNEL_HANGUP_COMPLETE'
        @call.removeListener 'CHANNEL_ANSWER', on_answer
        running = false

      debug '(Private) in-call script is ready.'

End-of-call handler
===================

      debug 'Setting handle_final'

      handle_final = (cdr_report) =>
        duration = Math.ceil( parseInt(cdr_report.billable,10) / seconds )

        debug 'handle_final', duration

        await incall_execute duration
          .catch (error) =>
            debug "incall_execute: #{error.stack ? error}"

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
