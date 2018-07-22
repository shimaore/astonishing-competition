    run = require 'flat-ornament'
    Rated = require 'entertaining-crib/rated'
    debug = (require 'tangible') 'astonishing-competition:runner'

    default_expire = -> Date.now() + 32*24*60*60*1000

Execute the ornaments
---------------------

    class Executor
      constructor: (@prefix,@commands) ->

      execute: (ornaments,cdr,br) ->
        debug 'Executor::execute', {cdr}

        pr = (name) -> "#{@prefix} #{name}"

        ctx = {
          cdr
          setup_counter: (name,expire) -> br.setup_counter (pr name), expire ? default_expire()
          update_counter: (name,value) -> br.update_counter (pr name), value
          get_counter: (name) -> br.get_counter (pr name)
        }
        await run.call ctx, ornaments, @commands
        return


    class Runner
      constructor: (@executor,@br) ->

Run code for a given CDR, loading and saving counters
-----------------------------------------------------

      run: (ornaments,cdr) ->

        debug 'run', cdr

        await @executor.execute ornaments, cdr, @br

        debug 'run completed', cdr
        return

Generate and evaluate a new CDR
-------------------------------

      evaluate: (ornaments,cdr,duration) ->

        debug 'evaluate', cdr, duration

For each step we compute the new values at the specified point-in-time.
Note: we must build a new `Rated` object since its duration can only be set once.

        cdr = new Rated cdr
        cdr.compute duration
        cdr = cdr.toJSON()

The billing rules may modify the working CDR, but not the original cdr.
This is done so that, when generating aggregated CDRs from rated CDRs, the `_id` and `_rev` fields esp. are not modified accidentally.
But, conversely, in a prepaid situation, the code running multiple times for the same call could store local values (using a `_` prefix) in the working-CDR (inside a single ornament-run).

        working_cdr = {}
        for own k,v of cdr when k[0] isnt '_'
          working_cdr[k] = v

        await @run ornaments, working_cdr

The billing rules may not modify values in the original, rated CDR,
nor the copy we send back.

        for own k,v of working_cdr when k[0] isnt '_'
          cdr[k] = v

        debug 'evaluate completed', cdr

        cdr

    module.exports = {Executor,Runner}
