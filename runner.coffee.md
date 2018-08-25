    run = require 'flat-ornament'
    Rated = require 'entertaining-crib/rated'
    debug = (require 'tangible') 'astonishing-competition:runner'
    moment = require 'moment'

    default_expire = -> moment().endOf('month').add(1,'day').valueOf()

Execute the ornaments
---------------------

    class Executor
      constructor: (@prefix,@commands,@br) ->

      run: (fun,cdr) ->
        debug 'Executor::execute', {cdr}

        pr = (name) => "#{@prefix} #{name}"

        ctx = {
          cdr
          update_counter: (name,value,expire) =>
            name = pr name
            @br.setup_counter name, expire ? default_expire()
            @br.update_counter name, value
          get_counter: (name) => @br.get_counter (pr name)
        }
        await fun.call ctx
        return

Generate and evaluate a new CDR
-------------------------------

      evaluate: (fun,cdr,duration) ->

        debug 'evaluate', cdr, duration

For each step we compute the new values at the specified point-in-time.
Note: we must build a new `Rated` object since its duration can only be set once.

        cdr = new Rated cdr
        cdr.compute duration
        cdr = cdr.toJS()

The billing rules may modify the working CDR, but not the original cdr.
This is done so that, when generating aggregated CDRs from rated CDRs, the `_id` and `_rev` fields esp. are not modified accidentally.
But, conversely, in a prepaid situation, the code running multiple times for the same call could store local values (using a `_` prefix) in the working-CDR (inside a single ornament-run).

        working_cdr = {}
        for own k,v of cdr when k[0] isnt '_'
          working_cdr[k] = v

        await @run fun, working_cdr

The billing rules may not modify values in the original, rated CDR,
nor the copy we send back.

        for own k,v of working_cdr when k[0] isnt '_'
          cdr[k] = v

        debug 'evaluate completed', cdr

        cdr

    module.exports = {Executor}
