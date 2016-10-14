    describe 'The middleware', ->
      it 'should load', ->
        m = require '../middleware/log-rated'
        m.server_pre.call cfg:{}
        m.include.call cfg:{}, respond: ->
