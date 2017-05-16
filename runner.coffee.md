    seem = require 'seem'
    run = require 'flat-ornament'
    Rated = require 'entertaining-crib/rated'
    debug = (require 'tangible') 'astonishing-competition:runner'

    {rate} = require './commands'

    sleep = require 'marked-summer/sleep'

    class Runner
      constructor: (@counters_db,@counters_id,@commands = rate) ->

      ornaments: (cdr) -> []

      is_private: -> true

      context: (cdr,counters) ->
        ctx =
          cdr: cdr
          counters: counters

Execute the ornaments, handling private changes to counters
-----------------------------------------------------------

Private changes are saved in the counters, but do not update the `official` counters (i.e. those used for billing).
This allows customer code to access the billing counters / state if needed, maintain their own counters, without interfering with billing.

      execute: seem (cdr,counters) ->

        ornaments = @ornaments cdr
        return unless ornaments?

        debug 'execute', ornaments

If we are executing untrusted code,

        is_private = @is_private()

        debug 'is_private', is_private

        if is_private

save the former values,

          former_counters = counters

and re-inject the private values into a new record.

          counters = {}
          for own k,v of former_counters.PRIVATE_COUNTERS when k[0] isnt '_'
            counters[k] = v
          for own k,v of former_counters when k[0] isnt '_'
            counters[k] = v
          delete counters.PRIVATE_COUNTERS

        ctx = @context cdr, counters

        debug 'run'

        yield run.call ctx, ornaments, @commands

If we are executing untrusted code,

        if is_private

save the private values

          PRIVATE = {}
          for own k,v of counters when k[0] isnt '_' and k not in former_counters
            PRIVATE[k] = v

and restore the former values.

          counters = former_counters
          counters.PRIVATE_COUNTERS = PRIVATE

        return

Run code for a given CDR, loading and saving counters
-----------------------------------------------------

      run: seem (cdr) ->

        debug 'run', cdr

It's very important that the billing-db be created with a `counters` record.

        ok = false
        while not ok
          counters = yield @counters_db.get @counters_id

          yield @execute cdr, counters

          ok = true
          counters._id = @counters_id
          counters.last = cdr._id
          yield @counters_db
            .put counters
            .catch ->

If the counters were modified while we were computing, do another loop.

              ok = false
              yield sleep Math.random 50

        cdr.counters = counters

        debug 'run completed', cdr
        return

Generate and evaluate a new CDR
-------------------------------

      evaluate: seem (cdr,duration) ->

        debug 'handle', duration

For each step we compute the new values at the specified point-in-time.
Note: we must build a new `Rated` object since its duration can only be set once.

        cdr = new Rated cdr
        cdr.compute duration
        cdr = cdr.toJSON()

The billing rules may modify the working CDR, but not the original cdr.
This is done so that, when generating aggregated CDRs from rated CDRs, the `_id` and `_rev` fields esp. are not modified accidentally.
But, conversely, in a prepaid situation, the code running multiple times for the same call could store intermediary values (using a `_` prefix) in the working-CDR.

        working_cdr = {}
        for own k,v of cdr when k[0] isnt '_'
          working_cdr[k] = v

        yield @run working_cdr

The billing rules may not modify values in the original, rated CDR,
nor the copy we send back.

        for own k,v of working_cdr when k[0] isnt '_'
          cdr[k] = v

        debug 'handle completed', cdr

        cdr

    module.exports = Runner
