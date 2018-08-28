    @name = "astonishing-competition:middleware:setup"
    {debug} = (require 'tangible') @name

    Rating = require 'entertaining-crib'
    PouchDB = require 'ccnq4-pouchdb'
    LRU = require 'lru-cache'
    BlueRing = require 'blue-rings'

* cfg.rating (object, optional) parameters for the rating of calls
* cfg.rating.source (string) name of the cfg.rating.tables source. Default: `default`
* cfg.rating.prefix (string) Prefix used to map a rating table name to a rating database. Default: `rates-`.

    DEFAULT_RATING_SOURCE = 'default'
    DEFAULT_RATING_PREFIX = 'rates-'

    cache = LRU
      max: 200
      dispose: (key,value) ->
        debug 'Dispose of', key
        value?.close?()

    rating_tables =
      _id: '_design/rating'
      language: 'coffeescript'
      views:
        tables:
          map: '''
            (doc) ->
              return if doc.disabled
              return unless doc.rating?
              for own k, v of doc.rating
                emit v.table if v.table?
            '''
          reduce: '_count'

At config time (i.e. before starting FreeSwitch)
-------

    @config = ->

      unless @cfg.prefix_admin? and @cfg.aggregation?
        debug.dev 'config: Skipping'
        return

Replicate the `plans` database (or whatever it's called in cfg.aggregation.plans).

      @cfg.aggregation.plans ?= 'plans'
      await @cfg.replicate @cfg.aggregation.plans

Replicate the `rates` databases.

Get the list of tables used in provisioning.

      await @cfg
        .push rating_tables
        .catch (error) ->
          debug.dev 'Inserting rating-tables couchapp failed (ignored).', error.stack ? JSON.stringify error

      {rows} = await @cfg.prov.query 'rating/tables',
        reduce: true
        group: true

We map the table name to a database name by applying a prefix, cfg.rating.prefix, which defaults to `rates-`.

      prefix = @cfg.rating?.prefix ? DEFAULT_RATING_PREFIX

      RatingPouchDB = PouchDB.defaults prefix: @cfg.prefix_admin

      for {key} in rows
        try
          name = "#{prefix}#{key}"
          target = new RatingPouchDB name, prefix: @cfg.prefix_admin
          await @cfg.reject_tombstones target
          await target.close()
          await @cfg.replicate name
        catch error
          debug.dev "Unable to replicate #{name} database.", error.stack ? JSON.stringify error

      debug 'config: Ready'

At server startup time
----------------------

    @server_pre = ->

      unless @cfg.prefix_admin? and @cfg.aggregation?
        debug.dev 'server_pre: Skipping'
        return

      @cfg.aggregation.plans ?= 'plans'
      @cfg.aggregation.PlansDB ?= new PouchDB "#{@cfg.prefix_admin}/#{@cfg.aggregation.plans}"

Prepare rating databases access (use local replica)

      prefix = @cfg.rating?.prefix ? DEFAULT_RATING_PREFIX

      RatingPouchDB = PouchDB.defaults prefix: @cfg.prefix_admin

      tables =  (key) ->
        name = "#{prefix}#{key}"
        db = cache.get name
        return db if db?
        db = new RatingPouchDB name
        cache.set name, db
        db


      @cfg.rating = new Rating
        source: @cfg.rating?.source ? DEFAULT_RATING_SOURCE
        rating_tables: @cfg.rating?.tables ? tables

Prepare counters

      @cfg.blue_rings ?= {}
      @cfg.blue_rings.Value ?= BlueRing.integer_values
      @cfg.br = BlueRing.run @cfg.blue_rings

      debug 'server_pre: Ready'

    @include = ->
