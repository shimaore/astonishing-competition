    extra_compilers =
      'cgu-fr': require './cgu-fr'

    module.exports = compile = (source,commands) ->
      default_compile source, commands, extra_compilers

    default_compile = require 'flat-ornament/compile'
