Aggregate CDRs
--------------

The role of this process is to turn a rated CDR (that went through `entertaining-crib` for rating) into a billable CDR. The billable CDR can then be used to build an invoice.

A billable CDR is one onto which billing rules have been applied. These rules may include dependencies outside of the CDR itself; typically there might be restrictions per billing cycle ("15h free per month, 0.02 thereafter") which might cause the amount computed for a given CDR to go up or down. In a prepaid application, billable CDRs will decide whether a call can proceed, its maximum duration, etc.

Restrictions and constraints are stored alongside the billable CDRs in a `counters` record. The record may be manipulated by the aggregation code following CouchDB rules (which means 409 errors are expected and should be handled appropriately), and each update MUST reference the CDR that caused the change in the `counters` record, while each CDR MUST be updated with the content of the `counters` record. Those two last constraints allow to rebuild the entire history of the counters record, the CDRs acting as as linked list.

    seem = require 'seem'
    run = require 'flat-ornament'

    sleep = (t) ->
      new Promise (accept,reject) ->
        setTimeout accept, t

    aggregate = seem (plans_db,billing_db,commands,cdr) ->

* doc.src_endpoint.rating[start-date].plan the name of the billing plan
* doc.plan Description of a billing plan.
* doc.plan.ornaments The [`flat-ornaments`](#pkg.flat-ornaments) implementation of the billing plan, using the commands described in the [`astonishing-competition`](#pkg.astonishing-competition) package.

      doc = yield plans_db
        .get "plan:#{cdr.rating.plan}"
        .catch -> null

      unless doc?
        return null

      {ornaments} = doc

It's very important that the billing-db be created with a `counters` record.

      ok = false
      while not ok
        counters = yield billing_db.get 'counters'

The billing rules may modify the working CDR.

        working_cdr = {}
        for own k,v of cdr when k[0] isnt '_'
          working_cdr[k] = v
        working_cdr._complete = false

        ctx =
          cdr: working_cdr
          counters: counters

        yield run.call ctx, ornaments, commands

        ok = true
        counters._id = 'counters'
        counters.last = cdr._id
        yield billing_db
          .put counters
          .catch ->

If the counters were modified while we were computing, do another loop.

            ok = false
            yield sleep Math.random 50

But the billing rules may not modify values in the original, rated CDR.

      for own k,v of working_cdr when k[0] isnt '_'
        cdr[k] = v
      cdr.counters = counters
      cdr

    {rate} = require './commands'
    @rate = (plans_db,billing_db,cdr) -> aggregate plans_db, billing_db, rate, cdr
