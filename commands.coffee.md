Algorithmitic pieces for contract (forfait) definition
-------------

    {validate} = require 'numbering-plans'

    commands =

Counters

      at_most:
        name:
          'fr-FR': 'au plus {0}'
        condition: (maximum,counter) ->
          @counters[counter] <= maximum

      count_calls:
        name:
          'fr-FR': 'appels'
        condition: (counter,value = 1) ->
          @cdr.incremented ?= {}
          @counters[counter] ?= 0
          unless @cdr.incremented[counter]
            @counters[counter] += value
            @cdr.incremented[counter] = true

      count_called:
        name:
          'fr-FR': 'destinataires'
        condition: (counter) ->
          @counters["_names_#{counter}"] ?= {}
          @counters["_names_#{counter}"][@cdr.remote_number] = true
          @counters[counter] = Object.keys(@counters["_names_#{counter}"]).length

      count_duration:
        name:
          'fr-FR': 'secondes'
        condition: (counter) ->
          @cdr.incremented ?= {}
          @counters[counter] ?= 0
          unless @cdr.incremented[counter]
            @counters[counter] += @cdr.duration
            @cdr.incremented[counter] = true

Destination conditions

      called_mobile:
        name:
          'fr-FR': 'vers les mobiles'
        condition: ->
          data = @cdr.rating_data
          unless data?.mobile?
            data = @cdr.rating_info = validate @cdr.remote_number
          return data?.mobile is true

      called_fixed:
        name:
          'fr-FR': 'vers les fixes'
        condition: ->
          data = @cdr.rating_data
          unless data?.fixed?
            data = @cdr.rating_info = validate @cdr.remote_number
          return data.fixed

      called_fixed_or_mobile:
        name:
          'fr-FR': 'vers les fixes et les mobiles'
        condition: ->
          data = @cdr.rating_data
          unless data?.mixed? or data?.fixed? or data?.mobile?
            data = @cdr.rating_info = validate @cdr.remote_number
          return data.mixed or data.fixed or data.mobile

      called_country:
        name:
          'fr-FR': 'vers {0}'
        condition: (countries) ->
          if typeof countries is 'string'
            countries = [countries]
          data = @cdr.rating_data
          unless data?.country?
            data = validate @cdr.remote_number
          return data.country in countries

Up-to
-----

Indicates what part of the call might be free.

      up_to:
        name:
          'fr-FR': "jusqu'à {1} minutes {0}"
        condition: (counter,up_to) ->
          up_to = up_to
          @cdr.incremented ?= {}
          @counters[counter] ?= 0
          unless @cdr.incremented[counter]
            @counters[counter] += value
            @cdr.incremented[counter] = true

      per_call_up_to:
        name:
          'fr-FR': "l'appel est gratuit jusqu'à {0} minutes"
        condition: (up_to) ->
          up_to = up_to
          @cdr.up_to ?= up_to

Keep the most restrictive value

          @cdr.up_to = up_to if @cdr.up_to > up_to
          true

Actions
-------

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
