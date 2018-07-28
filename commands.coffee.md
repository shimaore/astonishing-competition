Algorithmitic pieces for contract (forfait) definition
-------------

This code handles three stages in the call:
- `pre` (decides whether the call can be placed or not)
- `middle` (decides whether the call can continue or not)
- `rate`
Note: for now this only handles `rate` (postpaid aggregation after rating).
The code should also include tools to:
- do call authorization at start of call (for prepaid and account restrictions on postpaid)
- do counter updates during the call (for prepaid and account restrictions / fraud detection on postpaid)

    {validate} = require 'numbering-plans'
    Rated = require 'entertaining-crib/rated'
    moment = require 'moment-timezone'

Period
------

Counters might be automatically indexed based on a format-string for the calls' date and time.
This allows e.g. to have daily counters (the default) on top of "billing-period" counters.

`period_name` will translate a generic name (`day`) into an actual period string (as understood by moment.js).

    period_name = ( period = 'YYYY-MM-DD' ) ->

Shortcuts

      switch period

`day` is normally unambiguous, except on the first and last day of the billing period.

        when 'day'
          'YYYY-MM-DD'

'hour' is normally unamiguous.

        when 'hour'
          'YYYY-MM-DD HH'

`week` is highly ambiguous, since counters are reset at the start of the billing period.

        when 'week'
          'YYYY-w'

`day-of-week` is normally unambiguous, except on the first and last day of the billing period.

        when 'day-of-week'
          'd'

        else
          period


A proper 'Rated' CDR should have a `connect_stamp` field.

    cdr_period = ( cdr, period ) ->

      period = period_name period

Cache/memoize

      cdr.period ?= {}
      if cdr.period[period]?
        return cdr.period[period]

      cdr.period[period] = moment cdr.connect_stamp
        .tz cdr.timezone
        .format period

    counter_period = ( counter, cdr, period ) ->
      if typeof period is 'string'
        [counter,'PER',cdr_period cdr, period].join ' '
      else
        counter

Once per call
-------------

Ensure the operation is only ran once per call.
The operation might be sync or async.

    once_per_call = (cdr,counter,cb) ->
      name = "_incremented #{counter}"
      unless cdr[name]
        cdr[name] = true
        cb()

Ensure the operation is only ran once per call, and provide a delta.
The operation might be sync or async.

    delta_per_call = (cdr,counter,value,cb) ->
      name = "_incremented #{counter}"
      previous_value = cdr[name] ?= 0
      cdr[name] = value
      if value > previous_value
        cb value - previous_value

Commands
========

The following commands are meant to be executed in the context of this module's runner; that context currently contains:
- `cdr` — some CDR data, which can be freely modified by the code (changes are thrown away at the end of the call)
- `update_counter`, and `get_counter`, bound to a specific sub-account and context.

    commands =

Counter names typically should reflect the conditions attached to them.
For example: counter = `mobile` + `count_called` = "number of mobile phone called (per billing period)"

Counters
--------

Count the numbe of different destinations (numbers) called

- per billing period

      # 'fr-FR': 'destinataires {0} différents (par {1})'
      count_called: (counter,period) ->

          counter = counter_period counter, @cdr, period

          per_destination = ['@@@',counter,@cdr.remote_number].join ' '

          [coherent,exists] = await @update_counter per_destination, 1
          if exists is 1
            # just created ⇒ add to the actual counter
            await @update_counter counter, 1
          true

Increment a counter for this call (once)

- per billing period

      # 'fr-FR': 'incrémente {0} de {1} (par {2})'
      increment: (counter,value,period) ->
          counter = counter_period counter, @cdr, period
          await once_per_call @cdr, counter, => @update_counter counter, value
          true

Increment a counter with this call's duration or amount (once)

- per billing period

      # 'fr-FR': "incrémente {0} de la durée de l'appel (par {1})"
      increment_duration: (counter,period) ->
          counter = counter_period counter, @cdr, period
          await delta_per_call @cdr, counter, @cdr.duration, (delta) => @update_counter counter, delta
          true

      # 'fr-FR': "incrémente {0} du montant de l'appel (par {1})"
      increment_amount: (counter,period) ->
          counter = counter_period counter, @cdr, period
          await delta_per_call @cdr, counter, @cdr.actual_amount, (delta) => @update_counter counter, delta
          true

Counters conditions

      # 'fr-FR': 'au plus {0} {1} (par {2})'
      at_most: (maximum,counter,period) ->
          counter = counter_period counter, @cdr, period
          [coherent,value] = await @get_counter counter
          value <= maximum

Counter value

      get_counter: (counter,period) ->
        counter = counter_period counter, @cdr, period
        [coherent,value] = await @get_counter counter
        value

Destination conditions

      # 'fr-FR': 'vers les mobiles'
      called_mobile: ->
          data = @cdr.rating_info ?= validate @cdr.remote_number
          return data?.mobile or data?.mixed

      # 'fr-FR': 'vers les fixes'
      called_fixed: ->
          data = @cdr.rating_info ?= validate @cdr.remote_number
          return data?.fixed or data?.mixed

      # 'fr-FR': 'vers les fixes et les mobiles'
      called_fixed_or_mobile: ->
          data = @cdr.rating_info ?= validate @cdr.remote_number
          return data?.mixed or data?.fixed or data?.mobile

      # 'fr-FR': 'vers {0}'
      called_country: (countries) ->
          if typeof countries is 'string'
            countries = [countries]
          data = @cdr.rating_info ?= validate @cdr.remote_number
          return data?.country in countries

      # 'fr-FR': 'urgences'
      called_emergency: ->
          if @cdr.emergency then true else false

      # 'fr-FR': 'sur le réseau'
      called_onnet: ->
          if @cdr.onnet then true else false

Per-call conditions

      # per_call_at_most_duration
      # 'fr-FR': "Si l'appel dure moins de {0} secondes"
      atmost_duration: (maximum) ->
          @cdr.duration <= maximum

      # 'fr-FR': "Si l'appel est gratuit"
      is_free: ->
          @cdr.actual_amount is 0

      # per_call_at_most_amount
      # 'fr-FR': "Si l'appel coûte moins de {0}"
      atmost_amount: (maximum) ->
          @cdr.actual_amount <= maximum

Per-call functions

      # 'fr-FR': "La durée de l'appel"
      duration: ->
        @cdr.duration

      # 'fr-FR': "Le montant de l'appel"
      amount: ->
        @cdr.actual_amount

Up-to
-----

These operations modify the `actual_amount` of the CDR to reflect the fact that part of (or the entire) call might not be billed.
The typical setup is:
- `reset_up_to` to start a new "up-to" sentence
- `per_call_up_to` and/or `up_to` are then used to define what parts might be free
- `free` does the actual computation (and must be called last in the sentence).

      # 'fr-FR': 'Indépendamment, '
      reset_up_to: ->
          @cdr.up_to = null
          true

Restrict the free part of the call to the first `up_to` seconds of the call.

      # atmost_up_to
      # 'fr-FR': "jusqu'à {0} secondes par appel"
      per_call_up_to: (up_to) ->
          @cdr.up_to ?= up_to

Keep the most restrictive (lowest) value

          @cdr.up_to = up_to if @cdr.up_to > up_to
          true

The `up_to` command is both an action (it modifies the CDR) and a condition (it does not always return true).

      # 'fr-FR': "jusqu'à {0} secondes {1} (par {2})"
      up_to: (total_up_to,counter,period) ->
          counter = counter_period counter, @cdr, period
          [coherent,value] = await @get_counter counter

          commands.increment_duration.action.call this, counter

Do not apply free-call if the ceiling was already met at the start of the call.

          return false if value > total_up_to

          up_to = total_up_to - value
          @cdr.up_to ?= up_to

Keep the most restrictive (lowest) value

          @cdr.up_to = up_to if @cdr.up_to > up_to
          true

The actual semantics here are "call is free _up-to_ {the values specified previously in up-to or per-call-up-to}".

      # 'fr-FR': "l'appel est gratuit"
      free: ->
          if @cdr.up_to? and @cdr.duration > @cdr.up_to
            rated = new Rated @cdr
            rated.duration = @cdr.duration-@cdr.up_to
            rated.compute()
            @cdr.actual_amount = rated.actual_amount
          else
            @cdr.actual_amount = 0
          true

Actions
-------

      # 'fr-FR': "masquer l'appel"
      hide_call: ->
          @cdr.hide_call = true
          true

      # 'fr-FR': '.'
      stop: ->
          'over'

    module.exports = {commands,counter_period}
