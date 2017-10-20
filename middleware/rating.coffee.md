    pkg = require '../package.json'
    @name = "#{pkg.name}:middleware:rating"
    seem = require 'seem'

    Rating = require 'entertaining-crib'
    Rated = require 'entertaining-crib/rated'
    PouchDB = require 'shimaore-pouchdb-core'
      .plugin require 'pouchdb-adapter-http'
    LRU = require 'lru-cache'

* cfg.rating (object, optional) parameters for the rating of calls
* cfg.rating.source (string) name of the cfg.rating.tables source. Default: `default`
* cfg.rating.tables (URI prefix) used to access the rating tables of the entertaining-crib module. Default: cfg.prefix_admin (from nimble-direction, i.e. env.NIMBLE_PREFIX_ADMIN)

    cache = LRU
      max: 200
      dispose: (key,value) ->
        debug 'Dispose of', key
        value?.close?()

    @server_pre = ->
      @debug 'server_pre'
      @cfg.rating = new Rating
        source: @cfg.rating?.source ? 'default'
        rating_tables:
          if not @cfg.rating?.tables? or typeof @cfg.rating.tables is 'string'
            (name) =>
              db = cache.get name
              return db if db?
              db = new PouchDB name, prefix: @cfg.rating?.tables ? @cfg.prefix_admin
              cache.set name, db
              db
          else
            @cfg.rating?.tables
      @debug 'server_pre: Ready'

    @include = seem ->

* session.rated.client (Rated object from entertaining-crib) rating object, client-side
* session.rated.carrier (Rated object from entertaining-crib) rating object, carrier-side

      stamp = new Date().toISOString()

      params =
          direction: @session.cdr_direction
          to: @session.ccnq_to_e164
          from: @session.ccnq_from_e164
          stamp: stamp
          client: @session.endpoint # from huge-play (egress-only since 15.x)
          carrier: @session.winner # from tough-rate

      @debug 'Client is ', params.client?._id
      @debug 'Carrier is ', params.carrier?._id

      @session.rated = yield @cfg.rating
        .rate params
        .catch (error) =>
          @debug "rating_rate failed: #{error.stack ? error}"
          null

      @session.rated ?= {}
      @session.rated.params = params

So in the best case we get:
- session.rated.client
- session.rated.carrier
- session.rated.params

      switch

This is the case e.g. for calls to voicemail.

        when not params.direction?
          @debug 'Routing non-billable call: no direction provided'

This is the case e.g. for centrex-to-centrex (internal) calls.

        when params.direction is 'ingress' and not params.from? and not params.to?
          @debug 'Routing non-billable call: no billable number on ingress'

        when params.direction is 'centrex-internal'
          @debug 'Routing internal Centrex call'

System-wide configuration accepting non-billable calls.

        when not @session.rated?.client?
          switch

- ingress

            when params.direction is 'ingress' and @cfg.route_non_billable_ingress_calls
              @debug 'Routing non-billable ingress call: configuration allowed'

- both directions

            when @cfg.route_non_billable_calls
              @debug 'Routing non-billable call: configuration allowed'

Reject non-billable (client-side) calls otherwise.

            else

              @debug 'Unable to rate', @session.dialplan
              yield @respond '500 Unable to rate'
              @direction 'unable-to-rate'
              return

Accept billable calls.

        else
          @debug 'Routing'

      @session.rated.client ?= new Rated
        billable_number: 'none'
        connect_stamp: new Date().toJSON()
        remote_number: 'none'
        rating_data:
          initial:
            cost: 0
            duration: 0
          subsequent:
            cost: 0
            duration: 1
        rating:
          plan: false

      @debug 'session.rated', @session.rated

      @debug 'Ready'
