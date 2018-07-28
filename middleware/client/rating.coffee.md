    @name = "astonishing-competition:middleware:client:rating"
    {debug} = (require 'tangible') @name

    Rated = require 'entertaining-crib/rated'

This code may be called twice:
- once, at the beginning of the call (but before LCR routing) to handle the `client`-side code (especially ornaments)
- a second time, after LCR processing, to add the `carrier-side` parameter.

    @include = ->

      return unless @session?

* session.rated.client (Rated object from entertaining-crib) rating object, client-side
* session.rated.carrier (Rated object from entertaining-crib) rating object, carrier-side

      debug 'Creating params', @session.endpoint, @session.winner
      stamp = new Date().toISOString()

      params =
        direction: @session.cdr_direction
        to: @session.ccnq_to_e164
        from: @session.ccnq_from_e164
        stamp: stamp
        client: @session.endpoint # from huge-play (egress-only since 15.x)
        carrier: @session.winner # from tough-rate

      @debug 'Client  is ', params.client?._id
      @debug 'Carrier is ', params.carrier?._id

      @session.rated = await @cfg.rating
        .rate params
        .catch (error) =>
          @debug "rating_rate failed: #{error.stack ? error}"
          null

      @session.rated ?= {}
      @session.rated.params = params

So in the best case we get:
- session.rated.client
- session.rated.carrier
- session.rated.params

      switch

This is the case e.g. for calls to voicemail.

        when not params.direction?
          @debug 'Routing non-billable call: no direction provided'

This is the case e.g. for centrex-to-centrex (internal) calls.

        when params.direction is 'ingress' and not params.from? and not params.to?
          @debug 'Routing non-billable call: no billable number on ingress'

        when params.direction is 'centrex-internal'
          @debug 'Routing internal Centrex call'

System-wide configuration accepting non-billable calls.

        when not @session.rated?.client?
          switch

- ingress

            when params.direction is 'ingress' and @cfg.route_non_billable_ingress_calls
              @debug 'Routing non-billable ingress call: configuration allowed'

- both directions

            when @cfg.route_non_billable_calls
              @debug 'Routing non-billable call: configuration allowed'

Reject non-billable (client-side) calls otherwise.

            else

              @debug 'Unable to rate', @session.dialplan
              await @respond '500 Unable to rate'
              @direction 'unable-to-rate'
              return

Accept billable calls.

        else
          @debug 'Routing'

      @session.rated.client ?= new Rated
        billable_number: 'none'
        connect_stamp: new Date().toJSON()
        remote_number: 'none'
        rating_data:
          initial:
            cost: 0
            duration: 0
          subsequent:
            cost: 0
            duration: 1
        rating:
          plan: false
        per: 60
        divider: 1

      @debug 'session.rated', @session.rated

      @debug 'Ready'
