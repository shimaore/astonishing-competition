    seem = require 'seem'
    run = require 'flat-ornament'
    Rated = require 'entertaining-crib/rated'
    debug = (require 'tangible') 'astonishing-competition:runner'

    {rate} = require './commands'

    sleep = require 'marked-summer/sleep'


Execute the ornaments
---------------------

The "official" counters are directly affected by the ornaments.

    class PublicExecutor
      constructor: (@ornaments,@commands = rate) ->

      execute: seem (cdr,counters) ->
        debug 'PublicExecutor::execute', {cdr,counters}
        ctx = { cdr, counters }
        yield run.call ctx, @ornaments, @commands

Execute the ornaments, handling private changes to counters
-----------------------------------------------------------

Private changes are saved in the counters, but do not update the "official" counters (i.e. those used for billing).
This allows customer code to access the billing counters / state if needed, maintain their own counters, without interfering with billing.

Private Executor, used for untrusted code (for example user-controlled call limits).

    class PrivateExecutor extends PublicExecutor

      execute: seem (cdr,counters) ->

        debug 'PrivateExecutor::execute', {cdr,counters}

        former_counters = counters

        counters = {}
        for own k,v of former_counters.PRIVATE_COUNTERS when k[0] isnt '_'
          counters[k] = v
        for own k,v of former_counters when k[0] isnt '_'
          counters[k] = v
        delete counters.PRIVATE_COUNTERS

        ctx = { cdr, counters }
        yield run.call ctx, @ornaments, @commands

        private_counters = {}
        for own k,v of counters when k[0] isnt '_' and k not in former_counters
          private_counters[k] = v

        counters = former_counters
        counters.PRIVATE_COUNTERS = private_counters

        return

    class Counters
      constructor: (@counters_db,@counters_id) ->

It's very important that the billing-db be created with a `counters` record.

      get: ->
        @counters_db.get @counters_id

      set: seem (counters) ->
        ok = false
        while not ok
          counters._id = @counters_id
          yield @counters_db
            .put counters
            .then (-> ok = true), ->

If the counters were modified while we were computing, do another loop.

              ok = false
              yield sleep Math.random 50
        return

    class Runner
      constructor: (@counters,@executor) ->

Run code for a given CDR, loading and saving counters
-----------------------------------------------------

      run: seem (cdr) ->

        debug 'run', cdr

        counters = yield @counters.get()
        yield @executor.execute cdr, counters
        counters.last = cdr._id
        yield @counters.set counters
        cdr.counters = counters

        debug 'run completed', cdr
        return

Generate and evaluate a new CDR
-------------------------------

      evaluate: seem (cdr,duration) ->

        debug 'evaluate', cdr, duration

For each step we compute the new values at the specified point-in-time.
Note: we must build a new `Rated` object since its duration can only be set once.

        cdr = new Rated cdr
        cdr.compute duration
        cdr = cdr.toJSON()

The billing rules may modify the working CDR, but not the original cdr.
This is done so that, when generating aggregated CDRs from rated CDRs, the `_id` and `_rev` fields esp. are not modified accidentally.
But, conversely, in a prepaid situation, the code running multiple times for the same call could store local values (using a `_` prefix) in the working-CDR (inside a single ornamed-run).

        working_cdr = {}
        for own k,v of cdr when k[0] isnt '_'
          working_cdr[k] = v

        yield @run working_cdr

The billing rules may not modify values in the original, rated CDR,
nor the copy we send back.

        for own k,v of working_cdr when k[0] isnt '_'
          cdr[k] = v

        debug 'evaluate completed', cdr

        cdr

    module.exports = {PublicExecutor,PrivateExecutor,Counters,Runner}
