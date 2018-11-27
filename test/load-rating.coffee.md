    describe 'Modules', ->
      list = [
          'middleware/in-call'
          'middleware/client/rating'
          'middleware/client/log-rated'
        ]

      unit = (m) ->
        it "should load #{m}", ->
          ctx =
            cfg:
              sip_profiles:{}
              prefix_admin: 'http://admin:password@couchdb:5984'
              rating:
                plans: 'h'
            session:{}
            once: -> Promise.resolve null
            call:
              emit: ->
            req:
              variable: -> null
            debug: ->
          ctx.debug.dev = ->
          M = require "../#{m}"
          M.server_pre?.call ctx, ctx
          # M.include.call ctx, ctx

      for m in list
        unit m
