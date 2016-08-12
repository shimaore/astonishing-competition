    @name = "#{(require '../package').name}:middleware:log-rated"
    debug = (require 'debug') @name
    seem = require 'seem'
    fs = (require 'bluebird').promisify require 'fs'
    path = require 'path'
    PouchDB = require 'pouchdb'
    moment = require 'moment-timezone'

Save remotely by default, fallback to

    RemotePouchDB = null
    LocalPouchDB = null

Compute period

    period_for = (side) ->
      return unless side?
      side.period = moment
        .tz side.connect_stamp, side.timezone
        .format 'YYYY-MM'

    @init = ->

* cfg.rating.remote (string,URI,required) base URI for remote invoicing databases

      assert @cfg.rating?.remote?, 'Missing cfg.rating.remote'
      RemotePouchDB = PouchDB.defaults prefix: @cfg.rating.remote

* cfg.rating.local (string,path) directory where CDRs are stored if cfg.rating.remote fails. The directory must be present.

      assert @cfg.rating?.local?, 'Missing cfg.rating.local'
      LocalPouchDB = PouchDB.defaults prefix: @cfg.rating.local

    @include = seem ->

      safely_write = seem (database,data) ->
        data.database = database

        try
          remote_db = new RemotePouchDB database
          yield remote_db.put @session

        catch error

          try
            local_db = new LocalPouchDB database
            yield local_db.put data

          catch error
            yield fs.writeFileAsync path.join cfg.rating.local, "#{uuid.v4()}.json", JSON.stringify(data), 'utf-8'

          finally
            local_db.close()

        finally
          remote_db.close()

      @call.on 'rated', seem (rated) =>

We need to figure out:
- where we want to log: which databases (one for client side, one for carrier side)
- how we want to log it: what document identifier

        client = rated.client?.account ? 'unknown'
        carrier = rated.carrier?.carrier ? 'unknown'

We're saving three objects:
- the entire `@session` object, used for troubleshooting, into the trace_database

        period = period_for rated.client
        trace_database = ['trace',client,period].join '-'
        try
          yield safely_write trace_database, @session
        catch error
          debug 'safely_write trace_database', error.stack ? error

        client_database = ['rated',client,period].join '-'
        try
          yield safely_write client_database, rated.client
        catch error
          debug 'safely_write client_database', error.stack ? error

        if rated.carrier?
          period_for rated.carrier
          carrier_database = ['rated',carrier,rated.carrier.period].join '-'
          try
            yield safely_write carrier_database, rated.carrier
          catch error
            debug 'safely_write carrier_database', error.stack ? error
