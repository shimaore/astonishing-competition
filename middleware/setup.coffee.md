    @name = "astonishing-competition:middleware:rating"
    {debug} = (require 'tangible') @name

    Rating = require 'entertaining-crib'
    PouchDB = require 'ccnq4-pouchdb'
    LRU = require 'lru-cache'
    BlueRing = require 'blue-rings'

* cfg.rating (object, optional) parameters for the rating of calls
* cfg.rating.source (string) name of the cfg.rating.tables source. Default: `default`
* cfg.rating.tables (URI prefix) used to access the rating tables of the entertaining-crib module. Default: cfg.prefix_admin (from nimble-direction, i.e. env.NIMBLE_PREFIX_ADMIN)

    cache = LRU
      max: 200
      dispose: (key,value) ->
        debug 'Dispose of', key
        value?.close?()

    @server_pre = ->

Prepare rating databases access

      prefix = @cfg.rating?.tables ? @cfg.prefix_admin
      RatingPouchDB = PouchDB.defaults {prefix}

      debug 'server_pre', prefix

      @cfg.rating = new Rating
        source: @cfg.rating?.source ? 'default'
        rating_tables:
          if not @cfg.rating?.tables? or typeof @cfg.rating.tables is 'string'
            (name) ->
              db = cache.get name
              return db if db?
              db = new RatingPouchDB name
              cache.set name, db
              db
          else
            @cfg.rating?.tables

Prepare counters

      @cfg.blue_rings ?= {}
      @cfg.blue_rings.Value ?= BlueRing.integer_values
      @cfg.br = BlueRing.run @cfg.blue_rings

  debug 'server_pre: Ready'
