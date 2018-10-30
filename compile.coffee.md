    extra_compilers =
      'cgu-fr': (src,commands) ->
        parser = new cgu_fr.Parser()
        parser.yy.op = commands
        name = 0
        parser.yy.new_name = -> "name#{name++}"
        parser.parse src

    cgu_fr = require './cgu-fr'

    module.exports = compile = (source,commands) ->
      default_compile source, commands, extra_compilers

    default_compile = require 'flat-ornament/compile'
