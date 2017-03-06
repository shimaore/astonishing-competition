    chai = require 'chai'
    chai.should()
    seem = require 'seem'
    debug = (require 'debug') "#{(require '../package').name}:middleware:rating"
    PouchDB = (require 'pouchdb')
      .plugin require 'pouchdb-adapter-memory'
      .defaults adapter:'memory'
    describe 'rating', ->
      m1 = require '../middleware/rating'
      m2 = require '../middleware/log-rated'
      it 'should set `rated`', (done) ->
        @timeout 7*1000
        p = seem ->
          trigger = null
          ctx =
            cfg:
              rating:
                source: 'local'
                tables: PouchDB
              aggregation:
                remote: 'remote-'
                local: 'local-'
                plans: 'plans'
              safely_write: (db,cdr) ->
                cdr.should.have.property 'duration', 33
                cdr.should.have.property 'amount', 0
                done()

            session:
              cdr_direction:'egress'
              ccnq_to_e164: '18002288588'
              ccnq_from_e164: '33643482771'

Client-side data

              endpoint:
                _id: 'endpoint:something'
                rating:
                  '2016-01-01':
                    table: 'client+current'
                timezone: 'UTC'

Carrier-side data

              winner:
                rating:
                  '2016-01-01':
                    table: 'carrier+current'
                timezone: 'UTC'

            debug: ->
              debug 'module', arguments...
            respond: ->

            call:
              once: (event) ->
                switch event
                  when 'CHANNEL_ANSWER'
                    new Promise (resolve,reject) ->
                      setTimeout resolve, 1*1000
                  when 'CHANNEL_HANGUP_COMPLETE'
                    new Promise (resolve,reject) ->
                      setTimeout resolve, 3*1000
                  when 'cdr_report'
                    new Promise (resolve,reject) ->
                      ctx.session.cdr_report = billable: 32262
                      setTimeout resolve, 5*1000

            save_trace: ->

          debug 'server_pre'
          m1.server_pre.call ctx, ctx
          m2.server_pre.call ctx, ctx
          ctx.should.have.property 'cfg'
          ctx.cfg.should.have.property 'rating'

* cfg.rating.PouchDB ignore

          debug 'tables', ctx.cfg.rating.PouchDB
          db = new ctx.cfg.rating.PouchDB 'rates-client+current'
          yield db.put
            _id:'configuration'
            currency: 'EUR'
            divider: 1
            per: 60
            ready: true
          yield db.put
            _id:'prefix:1800'
            initial:
              cost: 0
              duration: 0
            subsequent:
              cost: 1
              duration: 60
          db.close()
          db = new ctx.cfg.rating.PouchDB 'rates-carrier+current'
          yield db.put
            _id:'configuration'
            currency: 'EUR'
            divider: 1
            per: 60
            ready: true
          yield db.put
            _id:'prefix:1800'
            initial:
              cost: 0
              duration: 0
            subsequent:
              cost: 0
              duration: 1
          db.close()

          debug 'include'
          yield m1.include.call ctx, ctx
          yield m2.include.call ctx, ctx
          debug 'include returned', ctx
          ctx.should.have.property 'session'
          ctx.session.should.have.property 'rated'
          ctx.session.rated.should.have.property 'client'
          ctx.session.rated.should.have.property 'carrier'

        p().catch done
        null
