    prepare_client_cdr = (cdr,account,sub_account) ->
      {
        _id: cdr._id

Parts of the `_id` (see `entertaining-crib/rated`: the fields are base-62 encoded to build the `_id`).

        B: cdr.billable_number
        C: cdr.connect_stamp
        R: cdr.remote_number
        D: cdr.duration

Account

        A: account
        S: sub_account

Outcome of the computation

        c: cdr.currency
        a: cdr.actual_amount

Extra data.

        d: cdr.direction
        e: cdr.rating_data?.destination
        p: cdr.rating.plan
        t: cdr.rating.table
        m: cdr.rating_info?.mobile
        n: cdr.rating_info?.full_name
      }

    prepare_carrier_cdr = (cdr) ->
      {
        _id: cdr._id

Parts of the `_id` (see `entertaining-crib/rated`: the fields are base-62 encoded to build the `_id`).

        B: cdr.billable_number
        C: cdr.connect_stamp
        R: cdr.remote_number
        D: cdr.duration

Outcome of the computation

        c: cdr.currency
        a: cdr.actual_amount
      }

    module.exports = {
      prepare_client_cdr
      prepare_carrier_cdr
    }
