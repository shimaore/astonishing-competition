    describe 'The middleware', ->
      it.skip 'should load rating', ->
        m = require '../middleware/client/rating'
        m.server_pre.call cfg:{}, debug: JSON.stringify
        m.include.call cfg:{ rating: rate: (->)}, respond: (->), debug: JSON.stringify, session:{}
      it 'should load in-call', ->
        m = require '../middleware/client/in-call'
        cfg = {}
        m.server_pre.call cfg:cfg, debug: (->)
        m.include.call cfg:cfg, respond: (->), debug: JSON.stringify, direction: (->), action: (-> await return)
        cfg.br.end()
      it.skip 'should load log-rated', ->
        m = require '../middleware/carrier/log-rated'
        cfg = {}
        m.server_pre.call cfg:cfg, debug: (->)
        m.include.call cfg:cfg, respond: (->), debug: JSON.stringify, direction: (->), action: (-> await return)
        cfg.br.end()
