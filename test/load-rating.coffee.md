    describe 'Modules', ->
      list = [
          'middleware/client/rating'
          'middleware/carrier/log-rated'
        ]

      unit = (m) ->
        it "should load #{m}", ->
          ctx =
            cfg:
              sip_profiles:{}
              prefix_admin: ''
            session:{}
            once: -> Promise.resolve null
            call:
              emit: ->
            req:
              variable: -> null
            debug: ->
          M = require "../#{m}"
          M.server_pre?.call ctx, ctx
          # M.include.call ctx, ctx

      for m in list
        unit m
