Aggregate CDRs
--------------

The role of this process is to turn a rated CDR (that went through `entertaining-crib` for rating) into a billable CDR. The billable CDR can then be used to build an invoice.

A billable CDR is one onto which billing rules have been applied. These rules may include dependencies outside of the CDR itself; typically there might be restrictions per billing cycle ("15h free per month, 0.02 thereafter") which might cause the amount computed for a given CDR to go up or down. In a prepaid application, billable CDRs will decide whether a call can proceed, its maximum duration, etc.

Restrictions and constraints are stored alongside the billable CDRs in a `counters` record. The record may be manipulated by the aggregation code following CouchDB rules (which means 409 errors are expected and should be handled appropriately), and each update MUST reference the CDR that caused the change in the `counters` record, while each CDR MUST be updated with the content of the `counters` record. Those two last constraints allow to rebuild the entire history of the counters record, the CDRs acting as as linked list.

    run = require 'flat-ornament'

    aggregate = (commands,cdr) ->

      billing_rules = yield rules_db.get cdr.rating.forfait

      ok = false
      while not ok
        counters = yield billing.get 'counters'

The billing rules may modify the working CDR.

        working_cdr = {}
        for own k,v of cdr
          working_cdr[k] = v
        working_cdr._complete = false

        ctx =
          cdr: working_cdr
          counters: counters

        yield run.call ctx, billing_ornaments, commands

        ok = true
        counters._id = 'counters'
        counters.last = cdr._id
        yield billing
          .put counters
          .catch ->

If the counters were modified while we were computing, do another loop.

            ok = false

But the billing rules may not modify values in the original, rated CDR.

      for own k,v of working_cdr when k[0] isnt '_'
        cdr[k] ?= v
      cdr.counters = counters
      safely_write billing_database, cdr

    {rate,restrict} = require './commands'
    @rate = (cdr) -> aggregate rate, cdr
    @restrict = (cdr) -> aggregate restrict, cdr
