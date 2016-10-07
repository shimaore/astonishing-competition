Algorithmitic pieces for contract (forfait) definition
-------------

Note: for now this only handles `rate` (postpaid aggregation after rating).
The code should also include tools to:
- do call authorization at start of call (for prepaid and account restrictions on postpaid)
- do counter updates during the call (for prepaid and account restrictions / fraud detection on postpaid)

    {validate} = require 'numbering-plans'

    commands =

Counters

      count_called:
        name:
          'fr-FR': 'destinataires {0}'
        action: (counter) ->
          @counters["_names_#{counter}"] ?= {}
          @counters["_names_#{counter}"][@cdr.remote_number] = true
          @counters[counter] = Object.keys(@counters["_names_#{counter}"]).length
          true

Increment

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

      increment_duration:
        name:
          'fr-FR': 'secondes {0}'
        action: (counter) ->
          @cdr.incremented ?= {}
          @counters[counter] ?= 0
          unless @cdr.incremented[counter]
            @counters[counter] += @cdr.duration
            @cdr.incremented[counter] = true
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

Up-to
-----

Indicates what part of the call might be free.

      per_call_up_to:
        name:
          'fr-FR': "jusqu'à {0} secondes par appel"
        action: (up_to) ->
          @cdr.up_to ?= up_to

Keep the most restrictive (lowest) value

          @cdr.up_to = up_to if @cdr.up_to > up_to
          true

      up_to:
        name:
          'fr-FR': "jusqu'à {0} secondes {1} mensuelles"
        condition: (total_up_to,counter) ->
          @cdr.incremented ?= {}
          @counters[counter] ?= 0
          value = @counters[counter]
          unless @cdr.incremented[counter]
            @counters[counter] += @cdr.duration
            @cdr.incremented[counter] = true
          return false if value > total_up_to
          up_to = total_up_to - value
          @cdr.up_to ?= value - up_to
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

      free:
        name:
          'fr-FR': "l'appel est gratuit"
        action: ->
          if @cdr.up_to? and @cdr.duration > @cdr.up_to
            rated = new Rated @cdr
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
