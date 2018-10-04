    {commands} = require '../commands'

    module.exports = ->

      endpoint = @session.rated.params.client
      incall_values = endpoint?.incall_values
      incall_values ?= {}

Note that `@ornaments_commands` is the standard `huge-play` set.
We need to map the functions because they are not bound to the call by `huge-play`, and need access to the call (they cannot use the context created by the Runner).

      ornaments_commands = {}
      for own k,v of @ornaments_commands
        ornaments_commands[k] = v.bind this

      Object.assign {}, ornaments_commands, commands,

Hangs the call up.

        hangup: =>
          await @respond '402 in-call restriction'
          await @action 'hangup', '402 in-call restriction'
          @direction 'rejected'
          'over'

Counter condition based on `incall_values`

        incall_atmost: (maximum_name,value) ->
          maximum = incall_values[maximum_name]
          return false unless maximum?
          return false unless 'number' is typeof maximum
          return false if isNaN maximum
          value <= maximum
