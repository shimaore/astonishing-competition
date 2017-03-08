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

    commands =

Counters

      count_called:
        name:
          'fr-FR': 'destinataires {0} différents'
        action: (counter) ->
          key = " @@@ #{counter}"
          @counters[key] ?= {}
          @counters[key][@cdr.remote_number] = true
          @counters[counter] = Object.keys(@counters[key]).length
          true

Increment a counter for this call (once)

      increment:
        name:
          'fr-FR': 'incrémente {0} de {1}'
        action: (counter,value = 1) ->
          @cdr.incremented ?= {}
          @counters[counter] ?= 0
          unless @cdr.incremented[counter]
            @counters[counter] += value
            @cdr.incremented[counter] = true
          true

Increment a counter with this call duration (once)

      increment_duration:
        name:
          'fr-FR': "incrémente {0} de la durée de l'appel"
        action: (counter) ->
          @cdr.incremented ?= {}
          @counters[counter] ?= 0
          @cdr.incremented[counter] ?= 0
          if @cdr.duration > @cdr.incremented[counter]
            @counters[counter] += @cdr.duration - @cdr.incremented[counter]
          @cdr.incremented[counter] = @cdr.duration
          true

Counters conditions

      at_most:
        name:
          'fr-FR': 'au plus {0} {1}'
        condition: (maximum,counter) ->
          @counters[counter] <= maximum

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

      up_to:
        name:
          'fr-FR': "jusqu'à {0} secondes {1} mensuelles"
        action: (total_up_to,counter) ->
          value = @counters[counter]

          commands.increment_duration.action.call this, counter

Do not apply free-call if the ceiling was already met at the start of the call.

          return false if value > total_up_to

          up_to = total_up_to - value
          @cdr.up_to ?= up_to

Keep the most restrictive (lowest) value

          @cdr.up_to = up_to if @cdr.up_to > up_to
          true

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
    for own k,v of commands when v.condition?
      @conditions[k] = v.condition
    @conditions.stop = commands.stop.action
    @conditions.hangup = ->
      @call.action 'hangup'
      @direction 'rejected'
      'over'
