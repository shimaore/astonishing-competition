    CouchDB = require 'most-couchdb'
    describe 'The middleware', ->
      debug = ->
      debug.dev = ->
      it 'should load setup', ->
        S = require '../middleware/setup'
        cfg = blue_rings: {pub: 23456}, prefix_admin: '', rating: {}
        await S.server_pre?.call cfg:cfg, debug: debug
        await S.include.call cfg:{ rating: rate: (->)}, respond: (->), debug: debug, session:{}
        await S.end()
      it 'should load setup (config)', ->
        S = require '../middleware/setup'
        provisioning = 'http://admin:password@couchdb:5984/provisioning'
        prov = new CouchDB provisioning
        after -> prov.destroy()
        await prov.create()
        cfg = prefix_admin: '', rating: {}, replicate: ->, push: (-> Promise.resolve()), provisioning: provisioning
        await S.config.call cfg:cfg, debug: debug
        await S.end()
      it 'should load client/rating', ->
        S = require '../middleware/setup'
        cfg = blue_rings: {pub: 23457}, prefix_admin: '', rating: {}
        S.server_pre.call cfg:cfg, debug: debug
        m = require '../middleware/client/rating'
        await m.server_pre?.call cfg:{}, debug: debug
        await m.include.call cfg:cfg, respond: (->), debug: debug, session:{}
        await S.end()
      it 'should load in-call', ->
        m = require '../middleware/in-call'
        cfg = rating: {plans: 'h'}
        await m.server_pre?.call cfg:cfg, debug: debug
        await m.include.call cfg:cfg, respond: (->), debug: debug, direction: (->), action: (-> await return)
      it 'should load client/log-rated', ->
        m = require '../middleware/client/log-rated'
        cfg = rating: {plans: 'h'}, prefix_admin: ''
        await m.server_pre?.call cfg:cfg, debug: debug
        await m.include.call cfg:cfg, respond: (->), debug: debug, direction: (->), action: (-> await return)
