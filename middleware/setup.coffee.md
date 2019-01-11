    @name = "astonishing-competition:middleware:setup"
    {debug,foot} = (require 'tangible') @name
    Nimble = require 'nimble-direction'
    ec = encodeURIComponent

    Rating = require 'entertaining-crib'
    CouchDB = require 'most-couchdb'

* cfg.rating (object, optional) parameters for the rating of calls
* cfg.rating.source (string) name of the cfg.rating.tables source. Default: `default`
* cfg.rating.prefix (string) Prefix used to map a rating table name to a rating database. Default: `rates-`.

    DEFAULT_RATING_SOURCE = 'default'
    DEFAULT_RATING_PREFIX = 'rates-'
    DEFAULT_RATING_PLANS  = 'plans'

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

    replicate_rating_tables = foot (cfg) ->

      N = Nimble cfg

Get the list of tables used in provisioning.

      await N
        .push rating_tables()
        .catch (error) ->
          debug.dev 'Inserting rating-tables couchapp failed (ignored).', error.stack ? JSON.stringify error

      rows = (new CouchDB N.provisioning).query 'rating', 'tables',
        reduce: true
        group: true

We map the table name to a database name by applying a prefix, cfg.rating.prefix, which defaults to `rates-`.

      prefix = cfg.rating?.prefix ? DEFAULT_RATING_PREFIX

      await rows.forEach ({key}) ->
        try
          debug.dev 'Requesting replication for', key
          name = "#{prefix}#{key}"
          uri = "#{N.prefix_admin}/#{ec name}"
          target = new CouchDB uri
          await target.create().catch -> yes
          await N.reject_tombstones target
          target = null
          await N.replicate name
        catch error
          debug.dev "Unable to replicate #{name} database.", error.stack ? JSON.stringify error

      return

At config time (i.e. before starting FreeSwitch)
-------

    timer1 = null
    timer2 = null

    @config = ->

      N = Nimble @cfg

Replicate the `plans` database (or whatever it's called in cfg.rating.plans).

      rating_plans = @cfg.rating?.plans ? DEFAULT_RATING_PLANS
      await N.replicate rating_plans

Replicate the `rates` databases.

The list is updated at startup,

      await replicate_rating_tables @cfg

ten minutes after startup (so that the view is ready),

      timer1 = setTimeout ( => await replicate_rating_tables @cfg ), 10*60*1000

and every 6h thereafter.

      timer2 = setInterval ( => await replicate_rating_tables @cfg ), 6*60*60*1000

      debug 'config: Ready'

At server startup time
----------------------

    @server_pre = ->

      N = Nimble @cfg

      rating_plans = @cfg.rating?.plans ? DEFAULT_RATING_PLANS
      @cfg.rating_plans = "#{N.prefix_admin}/#{rating_plans}"

Prepare rating databases access (use local replica)

      prefix = @cfg.rating?.prefix ? DEFAULT_RATING_PREFIX

      Tables = (key) =>
        name = "#{prefix}#{key}"
        uri = "#{N.prefix_admin}/#{ec name}"
        new CouchDB uri, true

      @cfg.rating = new Rating
        source: @cfg.rating?.source ? DEFAULT_RATING_SOURCE
        rating_tables: Tables

      debug 'server_pre: Ready'

    {rated_account,rated_sub_account} = require '../tools'

    @include = ->

      @cfg.rated_account ?= rated_account
      @cfg.rated_sub_account ?= rated_sub_account

    @end = ->
      clearTimeout  timer1 if timer1?
      clearInterval timer2 if timer2?
      return
