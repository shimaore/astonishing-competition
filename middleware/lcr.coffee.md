    @include = =>
      return unless @session?.direction is 'lcr' and @session.incall_script?
      await @session.incall_script()
      delete @session.incall_script
