    @name = "#{(require '../package').name}:middleware:log-rated"
    debug = (require 'debug') @name
    seem = require 'seem'
    fs = (require 'bluebird').promisifyAll require 'fs'
    path = require 'path'
    PouchDB = require 'pouchdb'
    moment = require 'moment-timezone'
    assert = require 'assert'

Save remotely by default, fallback to

    RemotePouchDB = null
    LocalPouchDB = null
    plans_db = null

    aggregate = require '../aggregation'

Compute period

    @init = ->
      debug 'init'

* cfg.rating.remote (string,URI,required) base URI for remote invoicing databases

      assert @cfg.rating?.remote?, 'Missing cfg.rating.remote'
      RemotePouchDB = PouchDB.defaults prefix: @cfg.rating.remote

* cfg.rating.local (string,path) directory where CDRs are stored if cfg.rating.remote fails. The directory must be present.

      assert @cfg.rating?.local?, 'Missing cfg.rating.local'
      LocalPouchDB = PouchDB.defaults prefix: @cfg.rating.local

      assert @cfg.rating?.plans?, 'Missing cfg.rating.plans'
      plans_db = new PouchDB @cfg.rating.plans

      @cfg.period_for ?= (side) ->
        return unless side?
        side.period = moment
          .tz side.connect_stamp, side.timezone
          .format 'YYYY-MM'

      @cfg.safely_write = seem (database,data) ->
        data.database = database

        try
          debug 'try remote db', database
          remote_db = new RemotePouchDB database
          yield remote_db.put data

        catch error

          try
            debug 'try local db', database
            local_db = new LocalPouchDB database
            yield local_db.put data

FIXME sync from local_db to remote_db in the background to ensure our local records eventually make it to the server
FIXME purge local_db so that it doesn't just grow in size indefinitely

          catch error
            debug 'save as JSON', database
            yield fs.writeFileAsync path.join @cfg.rating.local, "#{uuid.v4()}.json", JSON.stringify(data), 'utf-8'

FIXME upload locally-saved JSON files to remote-db

          finally
            local_db.close()

        finally
          remote_db.close()

    @include = ->

      unless plans_db and (RemotePouchDB? or LocalPouchDB?)
        unless @cfg.route_non_billable_calls
          debug 'Unable to rate'
          @respond '500 Unable to rate'
        return

      @call.on 'rated', seem (rated) =>

        debug 'rated'

We need to figure out:
- where we want to log: which databases (one for client side, one for carrier side)
- how we want to log it: what document identifier

        client = rated.client?.account ? 'unknown'
        carrier = rated.carrier?.carrier ? 'unknown'

        client_period = @cfg.period_for rated.client
        carrier_period = @cfg.period_for rated.carrier

We're saving three objects:

- a rated and aggregated `client` object, used for billing, into the rated-database

        client_database = ['rated',client,client_period].join '-'
        billing_db = new RemotePouchDB client_database
        yield remote_db
          .put _id:'counters'
          .catch -> yes

  Rate the CDR.

        yield aggregate.rate plans_db, billing_db, rated.client

        try
          unless rated.client.hide_call
            yield @cfg.safely_write client_database, rated.client
        catch error
          debug 'safely_write client_database', error.stack ? error

        yield billing_db.close()

- a rated `carrier` object, into the rated-database for the carrier.

        if rated.carrier?
          carrier_database = ['rated',carrier,carrier_period].join '-'
          try
            yield @cfg.safely_write carrier_database, rated.carrier
          catch error
            debug 'safely_write carrier_database', error.stack ? error

- the entire `@session` object, used for troubleshooting, into the trace-database
  (this includes the session.data object set in tough-rate and others)

  The trace-databases can be deleted after whatever period is convenient in terms
  of storage space and legal obligations.

        trace_database = ['trace',client,client_period].join '-'
        try
          yield @cfg.safely_write trace_database, @session
        catch error
          debug 'safely_write trace_database', error.stack ? error

        debug 'rated:done'

      debug 'Ready'
