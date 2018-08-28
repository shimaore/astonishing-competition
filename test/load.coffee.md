    describe 'The middleware', ->
      debug = ->
      debug.dev = ->
      it 'should load setup', ->
        S = require '../middleware/setup'
        cfg = blue_rings: {pub: 23456}, prefix_admin: '', aggregation: {}
        S.server_pre.call cfg:cfg, debug: debug
        S.include.call cfg:{ rating: rate: (->)}, respond: (->), debug: debug, session:{}
        S.end()
      it 'should load setup (config)', ->
        S = require '../middleware/setup'
        cfg = prefix_admin: '', aggregation: {}, replicate: ->, push: (-> Promise.resolve()), prov: {query: -> {rows:[]}}
        S.config.call cfg:cfg, debug: debug
        S.end()
      it 'should load tools', ->
        m = require '../middleware/tools'
        m.server_pre.call cfg:{}, debug: debug
        m.include.call cfg:{ rating: rate: (->)}, respond: (->), debug: debug, session:{}
      it 'should load client/rating', ->
        S = require '../middleware/setup'
        cfg = blue_rings: {pub: 23457}, prefix_admin: '', aggregation: {}
        S.server_pre.call cfg:cfg, debug: debug
        m = require '../middleware/client/rating'
        m.server_pre?.call cfg:{}, debug: debug
        m.include.call cfg:cfg, respond: (->), debug: debug, session:{}
        S.end()
      it 'should load in-call', ->
        m = require '../middleware/in-call'
        cfg = aggregation: plans: 'h'
        m.include.call cfg:cfg, respond: (->), debug: debug, direction: (->), action: (-> await return)
      it 'should load client/log-rated', ->
        m = require '../middleware/client/log-rated'
        cfg = aggregation: plans: 'h'
        m.server_pre.call cfg:cfg, debug: debug
        m.include.call cfg:cfg, respond: (->), debug: debug, direction: (->), action: (-> await return)
