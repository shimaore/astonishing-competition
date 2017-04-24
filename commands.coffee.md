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

    seem = require 'seem'
    {validate} = require 'numbering-plans'
    Rated = require 'entertaining-crib/rated'
    moment = require 'moment-timezone'

Period
------

Counters might be automatically indexed based on a format-string for the calls' date and time.
This allows e.g. to have daily counters (the default) on top of "billing-period" counters.

    cdr_period = ( cdr, period = 'YYYY-MM-DD' ) ->

Cache

      cdr.period ?= {}
      if cdr.period[period]?
        return cdr.period[period]

Shortcuts

      switch period

`day` is normally unambiguous, except on the first and last day of the billing period.

        when 'day'
          period = 'YYYY-MM-DD'

'hour' is normally unamiguous.

        when 'hour'
          period = 'YYYY-MM-DD HH'

`week` is highly ambiguous, since counters are reset at the start of the billing period.

        when 'week'
          period = 'YYYY-w'

`day-of-week` is normally unambiguous, except on the first and last day of the billing period.

        when 'day-of-week'
          period = 'd'

A proper 'Rated' CDR should have a `connect_stamp` field.

      cdr.period[period] = moment cdr.connect_stamp
        .tz cdr.timezone
        .format period

    counter_period = ( counter, cdr, period ) ->
      "#{counter} --- #{cdr_period cdr, period}"

    commands =

Counter names typically should reflect the conditions attached to them.
For example: counter = `mobile` + `count_called` = "number of mobile phone called (per billing period)"

Counters
--------

- per billing period

      count_called:
        name:
          'fr-FR': 'destinataires {0} différents'
        action: (counter) ->
          key = " @@@ #{counter}"
          @counters[key] ?= {}
          @counters[key][@cdr.remote_number] = true
          @counters[counter] = Object.keys(@counters[key]).length
          true

- per specified period (default: daily)

      count_called_per:
        name:
          'fr-FR': 'destinataires {0} différents par {1}'
        action: (counter,period) ->
          name = counter_period counter, @cdr, period
          commands.count_called.action.call this, name

Increment a counter for this call (once)

- per billing period

      increment:
        name:
          'fr-FR': 'incrémente {0} de {1}'
        action: (counter,value = 1) ->
          @counters[counter] ?= 0
          name = "_incremented #{counter}"
          unless @cdr[name]
            @counters[counter] += value
            @cdr[name] = true
          true

- per specified period (default: daily)

      increment_per:
        name:
          'fr-FR': 'incrémente {0} de {1} par {2}'
        action: (counter,value,period) ->
          name = counter_period counter, @cdr, period
          commands.increment.action.call this, name, value

Increment a counter with this call duration (once)

- per billing period

      increment_duration:
        name:
          'fr-FR': "incrémente {0} de la durée de l'appel"
        action: (counter) ->
          @counters[counter] ?= 0
          name = "_incremented #{counter}"
          @cdr[name] ?= 0
          if @cdr.duration > @cdr[name]
            @counters[counter] += @cdr.duration - @cdr[name]
          @cdr[name] = @cdr.duration
          true

- per specified period (default: daily)

      increment_duration_per:
        name:
          'fr-FR': "incrémente {0} par {1} de la durée de l'appel"
        action: (counter,period) ->
          name = counter_period counter, @cdr, period
          commands.increment_duration.action.call this, name

Counters conditions

- per billing period

      at_most:
        name:
          'fr-FR': 'au plus {0} {1}'
        condition: (maximum,counter) ->
          value = @counters[counter] ? 0
          value <= maximum

- per specified period (default: daily)

      at_most_per:
        name:
          'fr=FR': 'au plus {0} {1} par {2}'
        condition: (maximum,counter,period) ->
          name = counter_period counter, @cdr, period
          commands.at_most.condition.call this, maximum, name

Destination conditions

      called_mobile:
        name:
          'fr-FR': 'vers les mobiles'
        condition: ->
          data = @cdr.rating_info ?= validate @cdr.remote_number
          return data?.mobile or data?.mixed

      called_fixed:
        name:
          'fr-FR': 'vers les fixes'
        condition: ->
          data = @cdr.rating_info ?= validate @cdr.remote_number
          return data?.fixed or data?.mixed

      called_fixed_or_mobile:
        name:
          'fr-FR': 'vers les fixes et les mobiles'
        condition: ->
          data = @cdr.rating_info ?= validate @cdr.remote_number
          return data?.mixed or data?.fixed or data?.mobile

      called_country:
        name:
          'fr-FR': 'vers {0}'
        condition: (countries) ->
          if typeof countries is 'string'
            countries = [countries]
          data = @cdr.rating_info ?= validate @cdr.remote_number
          return data?.country in countries

      called_emergency:
        name:
          'fr-FR': 'urgences'
        condition: ->
          if @cdr.emergency then true else false

      called_onnet:
        name:
          'fr-FR': 'sur le réseau'
        condition: ->
          if @cdr.onnet then true else false

      atmost_duration:
        name:
          'fr-FR': "Si l'appel dure moins de {0} secondes"
        condition: (maximum)->
          @cdr.duration < maximum

      is_free:
        name:
          'fr-FR': "Si l'appel est gratuit"
        condition: ->
          @cdr.actual_amount is 0

      atmost_amount:
        name:
          'fr-FR': "Si l'appel coûte moins de {0}"
        condition: (maximum)->
          @cdr.actual_amount < maximum

Up-to
-----

      reset_up_to:
        name:
          'fr-FR': 'Indépendamment, '
        action: ->
          @cdr.up_to = null
          true

Indicates what part of the call might be free.

      per_call_up_to:
        name:
          'fr-FR': "jusqu'à {0} secondes par appel"
        action: (up_to) ->
          @cdr.up_to ?= up_to

Keep the most restrictive (lowest) value

          @cdr.up_to = up_to if @cdr.up_to > up_to
          true

The `up_to` command is both an action (it modifies the CDR) and a condition (it does not always return true).
Still marking it as an action so that it does not show up in the exported conditions.

- per billing period

      up_to:
        name:
          'fr-FR': "jusqu'à {0} secondes {1} par facture"
        action: (total_up_to,counter) ->
          value = @counters[counter] ? 0

          commands.increment_duration.action.call this, counter

Do not apply free-call if the ceiling was already met at the start of the call.

          return false if value > total_up_to

          up_to = total_up_to - value
          @cdr.up_to ?= up_to

Keep the most restrictive (lowest) value

          @cdr.up_to = up_to if @cdr.up_to > up_to
          true

- per specific period

      up_to_per:
        name:
          'fr=FR': "jusqu'à {0} secondes {1} par {2}"
        condition: (total_up_to,counter,period) ->
          name = counter_period counter, @cdr, period
          commands.up_to.action.call this, total_up_to, name

Actions
-------

      hide_call:
        name:
          'fr-FR': "masquer l'appel"
        action: ->
          @cdr.hide_call = true
          true

The actual semantics here are "call is free _up-to_ {the values specified previously in up-to or per-call-up-to}".

      free:
        name:
          'fr-FR': "l'appel est gratuit"
        action: ->
          if @cdr.up_to? and @cdr.duration > @cdr.up_to
            cdr =
              rating_data: @cdr.rating_data
              per: @cdr.per
              divider: @cdr.divider
            rated = new Rated cdr
            rated.compute @cdr.duration-@cdr.up_to
            @cdr.actual_amount = rated.actual_amount
          else
            @cdr.actual_amount = 0
          true

      stop:
        name:
          'fr-FR': '.'
        action: ->
          'over'

    @rate = {}
    for own k,v of commands
      @rate[k] = v.condition ? v.action

    @names = {}
    for own k,v of commands
      @names[k] = v.name

Used for start-of-call and mid-call conditions.

    @conditions = {}
    for own k,v of commands
      @conditions[k] = v.condition ? v.action
    @conditions.hangup = seem ->
      yield @respond '402 rating limit'
      yield @action 'hangup', '402 rating limit'
      @direction 'rejected'
      'over'
