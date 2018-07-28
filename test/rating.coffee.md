    ({expect} = require 'chai').should()
    debug = (require 'tangible') "#{(require '../package').name}:middleware:rating"
    PouchDB = require 'shimaore-pouchdb-core'
      .plugin require 'pouchdb-adapter-memory'
      .plugin require 'pouchdb-replication'
      .defaults adapter:'memory'
    moment = require 'moment-timezone'

    sleep = (timeout) -> new Promise (resolve) -> setTimeout resolve, timeout
    describe 'rating', ->
      s1 = require '../middleware/setup'
      s2 = require '../middleware/tools'
      m1 = require '../middleware/client/rating'
      m2 = require '../middleware/in-call'
      m3 = require '../middleware/carrier/log-rated'
      it 'should set `rated`', ->
        @timeout 7*1000

        day = new Date().toJSON()[0...10]
        per = day[0...7]

        seen = 0

        trigger = null
        ctx =
          cfg:
            period_of: (stamp,timezone) -> # default from huge-play/middleware/setup
                moment
                .tz stamp, timezone
                .format 'YYYY-MM'
            rating:
              source: 'local'
              tables: PouchDB
            aggregation:
              PlansDB: new PouchDB 'plans'
              LocalDB: (name) -> new PouchDB name

          ornaments_commands:
            display: ->
              true

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
              incall_script:
                language: 'v2'
                script: '''
                  increment('bear',2,'day'),
                  increment_duration('cat','day'),
                  display()
                '''

          debug: ->
            debug 'module', arguments...
          respond: ->
          direction: ->
          once: (event,resolve) ->
            switch event
              when 'cdr_report'
                setTimeout ( ->
                  ctx.session.cdr_report = billable: 32262
                  resolve ctx.session.cdr_report
                ), 5500

          call:
            event_json: -> Promise.resolve null
            once: (event,resolve) ->
              switch event
                when 'CHANNEL_ANSWER'
                  setTimeout resolve, 1*1000
                when 'CHANNEL_HANGUP_COMPLETE'
                  setTimeout resolve, 3*1000
            removeListener: ->

          save_trace: ->

        debug 'server_pre'
        s1.server_pre?.call ctx, ctx
        after -> ctx.cfg.br.end()
        s2.server_pre?.call ctx, ctx
        m1.server_pre?.call ctx, ctx
        m2.server_pre?.call ctx, ctx
        m3.server_pre?.call ctx, ctx
        ctx.should.have.property 'cfg'
        ctx.cfg.should.have.property 'rating'

        db = new PouchDB 'rates-client+current'
        await db.put
          _id:'configuration'
          currency: 'EUR'
          divider: 1
          per: 60
          ready: true
        await db.put
          _id:'prefix:1800'
          initial:
            cost: 4
            duration: 2
          subsequent:
            cost: 3
            duration: 60
        db.close()
        db = new PouchDB 'rates-carrier+current'
        await db.put
          _id:'configuration'
          currency: 'EUR'
          divider: 1
          per: 60
          ready: true
        await db.put
          _id:'prefix:1800'
          initial:
            cost: 0
            duration: 0
          subsequent:
            cost: 1
            duration: 1
        db.close()

        debug 'include'
        await m1.include.call ctx, ctx
        ctx.should.have.property 'session'
        ctx.session.should.have.property 'rated'
        ctx.session.rated.should.have.property 'client'
        ctx.session.rated.params.client.should.equal ctx.session.endpoint

        await m2.include.call ctx, ctx
        await m3.include.call ctx, ctx
        debug 'include returned', ctx

Carrier-side data

        await sleep 5000
        ctx.session.winner =
          _id: 'carrier:bob the carrier'
          carrier: 'bob the carrier'
          rating:
            '2016-01-01':
              table: 'carrier+current'
          timezone: 'UTC'
        await m1.include.call ctx, ctx
        ctx.session.rated.should.have.property 'carrier'
        ctx.session.rated.params.carrier.should.equal ctx.session.winner
        ctx.session.rated.carrier.should.have.property 'currency', 'EUR'

Wait for cdr-report to be sent

        await sleep 1000

        debug 'ctx.session.rated', ctx.session.rated

        ctx.session.rated.client.should.have.property 'duration', 33
        ctx.session.rated.client.should.have.property 'amount', 7

        ctx.session.rated.carrier.should.have.property 'duration', 33
        ctx.session.rated.carrier.should.have.property 'amount', 0.55

        (await ctx.cfg.br.get_counter "α unknown-account #{per} cat PER #{day}").should.have.property 1, 33

        null
