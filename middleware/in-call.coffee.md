    @name = "astonishing-competition:middleware:client:in-call"
    {debug,foot,heal} = (require 'tangible') @name
    PouchDB = require 'ccnq4-pouchdb'
    moment = require 'moment'

    plans_db = null

    {Executor} = require '../../runner'
    {commands} = require '../../commands'
    {get_ornaments} = require '../../get_ornaments'
    compile = require '../../compile'
    sleep = require 'marked-summer/sleep'
    sleep_until = (time) ->
      now = moment.utc()
      if time.isAfter now
        sleep time.diff now

    seconds = 1000

Compute period

    @server_pre = ->

      if @cfg.aggregation?.plans?
        plans_db = new PouchDB @cfg.aggregation.plans
      else
        unless @cfg.route_non_billable_calls
          throw new Error 'Missing cfg.aggregation.plans'

Call handler
============

    @include = ->

      @debug 'Start'

These are all preconditions. None of them should fail unless the proper modules are not loaded.
(In other words these all indicate developer errrors.)

      fail = =>
        await @respond '500 Unable to rate'
        @direction 'failed'

      unless @session?
        @debug.dev 'No session'
        fail()
        return

      unless plans_db
        unless @cfg.route_non_billable_calls
          @debug.dev 'No plans_db'
          fail()
        return

      unless @session.rated?
        @debug.dev 'No session.rated'
        fail()
        return

      unless @session.rated.params?
        @debug.dev 'No session.rated.params'
        fail()
        return

Remember, we expect to have:
- session.rated.client (might be missing)
- session.rated.params, esp session.rated.params.client and session.rated.params.carrier.

Client setup
------------

### Before the call starts.

      client_cdr = @session.rated.client

      unless client_cdr?
        @debug 'No session.rated.client'
        return

      @debug 'Preprocessing client', client_cdr

      plan_script = await get_ornaments plans_db, client_cdr

Counters are handled at the `sub_account` level (although we could also have `account`-level counters, I guess).

      sub_account = @cfg.rated_sub_account @session.rated

      client_period = @cfg.period_for_client @session.rated

Counters at the sub-account level.

      counters_prefix = ['counters',sub_account,client_period].join ' '

Rating ornament
===============

Ornaments might be set on the endpoint to add decisions as to whether the call should proceed or not, or be interrupted at some point.

* doc.endpoint.incall_script used to decide whether the call can proceed. Uses commands from astonishing-competition/commands.conditions: `at_most(maximum,counter)`, `called_mobile`, `called_fixed`, `called_fixed_or_mobile`, `called_country(countries|country)`, `called_emergency`, `called_onnet`, `up_to(total,counter)`, `free`, `hangup`.
* doc.endpoint.incall_values (hash) used in doc.endpoint.incall code as parameters; for example it is used by the `at_most_value` function to take decisions based on endpoint-specific parameters (for example to set a per-endpoint maximum amount of money to spend per billing period).

      endpoint = @session.rated.params.client
      private_script = endpoint?.incall_script
      private_script ?= endpoint?.rating_ornaments # legacy

      if private_script?
        @debug 'Processing (private) in-call script.'

        {incall_values} = @session.rated.params.client
        incall_values ?= {}

Note that `@ornaments_commands` is the standard `huge-play` set.
We need to map the functions because they are not bound to the call by `huge-play`, and need access to the call (they cannot use the context created by the Runner).

        ornaments_commands = {}
        for own k,v of @ornaments_commands
          ornaments_commands[k] = v.bind this

        private_commands = Object.assign {}, ornaments_commands, commands,

Hangs the call up.

          hangup: =>
            await @respond '402 in-call restriction'
            await @action 'hangup', '402 in-call restriction'
            @direction 'rejected'
            'over'

Counter condition based on `incall_values`

          incall_atmost: (maximum_name,value,period) ->
            maximum = incall_values[maximum_name]
            return false unless maximum?
            return false unless 'number' is typeof maximum
            return false if isNaN maximum
            value <= maximum

        private_fun = try compile private_script, private_commands
        private_fun ?= ->
        plan_fun = try compile plan_script, private_commands
        plan_fun ?= ->

Private changes are saved in the counters, but do not update the "official" counters (i.e. those used for billing).
This allows customer code to maintain their own counters, without interfering with billing.

        private_executor = new Executor "P #{counters_prefix}", private_commands, @cfg.br

### Definition

        private_cdr = {}

        incall_execute = (duration) ->

          debug 'incall_execute', duration

Compute the CDR at that point in time.

          incall_cdr = await private_executor.evaluate plan_fun, client_cdr, duration

Then execute the decision code on the updated CDR.

          unless incall_cdr.hide_call
            Object.assign private_cdr, incall_cdr
            await private_executor.run private_fun, private_cdr

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
          @debug.csr 'No initial duration available'
          await @respond '500 no initial duration available'
          @direction 'failed'
          return

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

        @debug '(Private) in-call script is ready.'

Handle both the case where the call is over (sync)

      handle_final = (cdr_report) =>
        duration = Math.ceil( parseInt(cdr_report.billable,10) / seconds )

        debug 'handle_final', duration

        await incall_execute? duration
          .catch (error) =>
            debug "incall_execute: #{error.stack ? error}"

      if @session.cdr_report?
        heal handle_final @session.cdr_report

or in-progress (async)

      else
        @once 'cdr_report', (report) ->
          heal handle_final report
          return

      return
