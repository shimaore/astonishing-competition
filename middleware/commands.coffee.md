    {commands} = require '../commands'
    {validate} = require 'numbering-plans'
    debug = (require 'tangible') 'astonishing-competition:middleware:commands'

    module.exports = ->

      endpoint = @session.rated.params.client
      incall_values = endpoint?.incall_values
      incall_values ?= {}

Note that `@ornaments_commands` is the standard `huge-play` set.
We need to map the functions because they are not bound to the call by `huge-play`, and need access to the call (they cannot use the context created by the Runner).

      ornaments_commands = {}
      for own k,v of @ornaments_commands
        ornaments_commands[k] = v.bind this

      {session} = this

      Object.assign {}, ornaments_commands, commands,

Hangs the call up.

        hangup: =>
          await @respond '402 in-call restriction'
          await @action 'hangup', '402 in-call restriction'
          @direction 'rejected'
          'over'

Other call-based conditions.

Notice that these (especially `onnet`) are not fulfilled during the very first test, only after LCR code has been evaluated.

        called_emergency: ->
          debug 'called_emergency (1)', session.destination_emergency
          return true if session.destination_emergency
          data = @cdr.rating_info ?= validate @cdr.remote_number
          debug 'called_emergency (2)', data?.emergency
          return data?.emergency

        called_onnet: ->
          debug 'called_onnet', session.destination_onnet
          session.destination_onnet ? null

Counter condition based on `incall_values`

        incall_atmost: (maximum_name,value) ->
          maximum = incall_values[maximum_name]
          debug 'incall_atmost', maximum_name, value, maximum
          return true if not maximum?
          return false unless 'number' is typeof maximum
          return false if isNaN maximum
          value <= maximum

Allow acces to various values, esp. the ones in `incall_values`.
`if the max_amount_per_day of the endpoint …`

        endpoint: ->
          get: (what) ->
            switch
              when what of incall_values
                incall_values[what]
              else
                null
