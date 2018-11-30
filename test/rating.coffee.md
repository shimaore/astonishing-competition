    ({expect} = require 'chai').should()
    debug = (require 'tangible') "#{(require '../package').name}:test:rating"
    CouchDB = require 'most-couchdb'
    BlueRing = require 'blue-rings'
    moment = require 'moment-timezone'
    ec = encodeURIComponent

    prefix = 'http://admin:password@couchdb:5984'

    sleep = (timeout) -> new Promise (resolve) -> setTimeout resolve, timeout
    describe 'rating', ->
      s1 = require '../middleware/setup'
      m1 = require '../middleware/client/rating'
      m2 = require '../middleware/in-call'
      m3 = require '../middleware/client/log-rated'

      plans_db = new CouchDB prefix+'/'+'plans'
      db1 = new CouchDB prefix+'/'+ec 'rates-client+current'
      db2 = new CouchDB prefix+'/'+ec 'rates-carrier+current'
      before ->
        try await plans_db.create()
        try await db1.create()
        try await db2.create()
      after ->
        try await plans_db.destroy()
        try await db1.destroy()
        try await db2.destroy()

      it 'should set `rated`', ->
        @timeout 7*1000

        day = new Date().toJSON()[0...10]
        per = day[0...7]

        seen = 0

        trigger = null
        ctx =
          cfg:
            rating:
              source: 'local'
            prefix_admin: prefix

          ornaments_commands:
            display: (args...) ->
              console.log args...
              true
            tag: (tag) ->
              @tag = tag

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
                  plan: 'youpi'
              timezone: 'UTC'
              incall_script:
                language: 'v2'
                script: '''
                  increment('bear',2,'day')
                  increment_duration('cat','day')
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
        ctx.cfg.br = BlueRing.run host: 'A'
        after -> ctx.cfg.br.end()
        m1.server_pre?.call ctx, ctx
        m2.server_pre?.call ctx, ctx
        m3.server_pre?.call ctx, ctx
        ctx.should.have.property 'cfg'
        ctx.cfg.should.have.property 'rating'
        ctx.cfg.should.have.property 'rating_plans'

        await plans_db.put
          _id: 'plan:youpi'
          script:
            language: 'v2'
            script: '''
              lun_ven = weekdays(1,2,3,4,5)
              samedi = weekdays(6)
              dimanche = weekdays(0)

              if lun_ven
                tag('everyone')
              if samedi
                tag('dedicated')
              if dimanche
                tag('closed')
                display("Are you really testing on a Sunday??")

            '''

        await db1.put
          _id:'configuration'
          currency: 'EUR'
          divider: 1
          per: 60
          ready: true
        await db1.put
          _id:'prefix:1800'
          initial:
            cost: 4
            duration: 2
          subsequent:
            cost: 3
            duration: 60

        await db2.put
          _id:'configuration'
          currency: 'EUR'
          divider: 1
          per: 60
          ready: true
        await db2.put
          _id:'prefix:1800'
          initial:
            cost: 0
            duration: 0
          subsequent:
            cost: 1
            duration: 1

        await s1.include.call ctx, ctx
        await m1.include.call ctx, ctx
        ctx.should.have.property 'session'
        ctx.session.should.have.property 'rated'
        ctx.session.rated.should.have.property 'client'
        ctx.session.rated.params.client.should.equal ctx.session.endpoint

        await m2.include.call ctx, ctx
        await m3.include.call ctx, ctx

Carrier-side data

        await sleep 5000
        ctx.session.gateway =
          _id: 'carrier:bob-the-carrier'
          carrier: 'bob-the-carrier'
          rating:
            '2016-01-01':
              table: 'carrier+current'
          timezone: 'UTC'

Wait for cdr-report to be sent

        await sleep 1000

        debug 'ctx.session.rated', ctx.session.rated
        ctx.session.rated.should.have.property 'carrier'
        ctx.session.rated.params.carrier.should.equal ctx.session.gateway
        ctx.session.rated.carrier.should.have.property 'currency', 'EUR'

        ctx.session.rated.client.should.have.property 'duration', 33
        ctx.session.rated.client.should.have.property 'amount', 7

        ctx.session.rated.carrier.should.have.property 'duration', 33
        ctx.session.rated.carrier.should.have.property 'amount', 0.55

        ctx.should.have.property('tag').that.is.a.string

        (await ctx.cfg.br.get_counter "α unknown-account #{per} cat PER #{day}").should.have.property 1, 33

        null
