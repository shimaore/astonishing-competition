Compute period.

    period_of = (stamp = new Date(),timezone = 'UTC') ->
      Moment
      .tz stamp, timezone
      .format 'YYYY-MM'

    cdr_period_of = (stamp = new Date(),timezone = 'UTC') ->
      Moment
      .tz stamp, timezone
      .format 'YYYY-MM-DD'

Maps a rated.client or rated.carrier into a period.

    period_for = (side) ->
      return unless side?
      side.period = period_of side.connect_stamp, side.timezone

    cdr_period_for = (side) ->
      return unless side?
      side.cdr_period = cdr_period_of side.connect_stamp, side.timezone

Computes a sub-account unique identifier based on a rated CDR.

    rated_sub_account = (rated) ->
      p = rated.params.client
      switch
        when p?.account? and p?.sub_account?
          [p.account,p.sub_account].join '_'
        when p?.account?
          p.account
        else
          'unknown-account'

Computes an account unique identifier based on a rated CDR.

    rated_account = (rated) ->
      p = rated.params.client
      switch
        when p?.account?
          p.account
        else
          'unknown-account'

Computes a carrier unique identifier based on a rated CDR.

    rated_carrier = (rated) ->
      rated.params.carrier?.carrier ? 'unknown-carrier'

    module.exports = {
      period_for
      cdr_period_for
      rated_sub_account
      rated_account
      rated_carrier
    }
    Moment = require 'moment-timezone'
