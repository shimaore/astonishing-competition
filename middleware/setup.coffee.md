    @name = "astonishing-competition:middleware:setup"
    {debug,foot} = (require 'tangible') @name

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


    rating_tables = ->
      yesterday = Date.now()-24*60*60*1000
      today = new Date(yesterday).toJSON()[0...10]
      debug "Replication will consider the last table before #{today} and any after that."

      _id: '_design/rating'
      language: 'coffeescript'
      views:
        tables:
          map: """
            (doc) ->
              return if doc.disabled
              return unless doc.rating?
              dates = Object.keys(doc.rating).sort()
              last = null
              for d in dates
                v = doc.rating[d].table
                if d < '#{today}'
                  last = v
                else
                  emit v if v?
              emit last if last?
            """
          reduce: '_count'

    replicate_rating_tables = foot ->

Get the list of tables used in provisioning.

      await @cfg
        .push rating_tables()
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
          target = new RatingPouchDB name
          await @cfg.reject_tombstones target
          await target.close()
          await @cfg.replicate name
        catch error
          debug.dev "Unable to replicate #{name} database.", error.stack ? JSON.stringify error

At config time (i.e. before starting FreeSwitch)
-------

    timer = null

    @config = ->

      unless @cfg.prefix_admin? and @cfg.aggregation?
        debug.dev 'config: Skipping'
        return

Replicate the `plans` database (or whatever it's called in cfg.aggregation.plans).

      @cfg.aggregation.plans ?= 'plans'
      await @cfg.replicate @cfg.aggregation.plans

Replicate the `rates` databases.

The list is updated at startup,

      do replicate_rating_tables.bind(this)

and every 24h thereafter.

      timer = setInterval replicate_rating_tables.bind(this), 24*60*60*1000

      debug 'config: Ready'

At server startup time
----------------------

    br = null

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
      @cfg.br = br = BlueRing.run @cfg.blue_rings

      debug 'server_pre: Ready'

    @include = ->

    @end = ->
      clearInterval timer if timer?
      br?.end()
      return
