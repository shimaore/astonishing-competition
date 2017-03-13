    describe 'The middleware', ->
      it.skip 'should load rating', ->
        m = require '../middleware/rating'
        m.server_pre.call cfg:{}, debug: (->)
        m.include.call cfg:{ rating: rate: (->)}, respond: (->), debug: (->), session:{}
      it 'should load log-rated', ->
        m = require '../middleware/log-rated'
        m.server_pre.call cfg:{}, debug: (->)
        m.include.call cfg:{}, respond: (->), debug: (->)
