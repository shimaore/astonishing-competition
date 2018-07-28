    describe 'The middleware', ->
      debug = ->
      debug.dev = ->
      it 'should load setup', ->
        m = require '../middleware/setup'
        cfg = blue_rings: pub: 23456
        m.server_pre.call cfg:cfg, debug: debug
        m.include.call cfg:{ rating: rate: (->)}, respond: (->), debug: debug, session:{}
        cfg.br.end()
      it 'should load tools', ->
        m = require '../middleware/tools'
        m.server_pre.call cfg:{}, debug: debug
        m.include.call cfg:{ rating: rate: (->)}, respond: (->), debug: debug, session:{}
      it 'should load client/rating', ->
        m = require '../middleware/setup'
        cfg = blue_rings: pub: 23457
        m.server_pre.call cfg:cfg, debug: debug
        m = require '../middleware/client/rating'
        m.server_pre?.call cfg:{}, debug: debug
        m.include.call cfg:cfg, respond: (->), debug: debug, session:{}
        after -> cfg.br.end()
      it 'should load in-call', ->
        m = require '../middleware/in-call'
        cfg = aggregation: plans: 'h'
        m.server_pre.call cfg:cfg, debug: debug
        m.include.call cfg:cfg, respond: (->), debug: debug, direction: (->), action: (-> await return)
      it 'should load carrier/log-rated', ->
        m = require '../middleware/carrier/log-rated'
        cfg = aggregation: plans: 'h'
        m.server_pre.call cfg:cfg, debug: debug
        m.include.call cfg:cfg, respond: (->), debug: debug, direction: (->), action: (-> await return)
