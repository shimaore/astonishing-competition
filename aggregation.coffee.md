Aggregate CDRs
--------------

The role of this process is to turn a rated CDR (that went through `entertaining-crib` for rating) into a billable CDR. The billable CDR can then be used to build an invoice.

A billable CDR is one onto which billing rules have been applied. These rules may include dependencies outside of the CDR itself; typically there might be restrictions per billing cycle ("15h free per month, 0.02 thereafter") which might cause the amount computed for a given CDR to go up or down. In a prepaid application, billable CDRs will decide whether a call can proceed, its maximum duration, etc.

Restrictions and constraints are stored alongside the billable CDRs in a `counters` record. The record may be manipulated by the aggregation code following CouchDB rules (which means 409 errors are expected and should be handled appropriately), and each update MUST reference the CDR that caused the change in the `counters` record, while each CDR MUST be updated with the content of the `counters` record. Those two last constraints allow to rebuild the entire history of the counters record, the CDRs acting as as linked list.

    seem = require 'seem'
    Runner = require './runner'

Aggregator
==========

The Aggregator is used to run the plan's actual billing code.

    class Aggregator
      constructor: (@plans_db,counters_db,counters_id,@cdr,commands) ->
        @runner = new Runner counters_db, counters_id, commands

      is_private: -> false

* doc.src_endpoint.rating[start-date].plan the name of the billing plan
* doc.plan Description of a billing plan.
* doc.plan.ornaments The [`flat-ornaments`](#pkg.flat-ornaments) implementation of the billing plan, using the commands described in the [`astonishing-competition`](#pkg.astonishing-competition) package.

      handle: seem (duration) ->
        ornaments = yield @ornaments()
        return unless ornaments?
        yield @runner.evaluate @cdr, duration, ornaments

      ornaments: seem ->

Memoize

        return @__ornaments if @__ornaments?

Special value: the rating plan might be `false`, indicating no plan aggregation code should be loaded (but aggregation should still succeed).

        if @cdr?.rating?.plan is false
          return @__ornaments = []

Otherwise, get the list of ornaments from the billing plan.

        doc = yield @plans_db
          .get "plan:#{@cdr.rating.plan}"
          .catch -> null

        unless doc?
          return null

        {ornaments} = doc

        @__ornaments = ornaments

    module.exports = Aggregator
