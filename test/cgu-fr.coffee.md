    fs = require 'fs'
    describe 'The CGU', ->
      it 'should compile', ->
        {Parser} = require '../cgu-fr'
        parser = new Parser()
        name = 0
        parser.yy.new_name = -> "name#{name++}"
        parser.yy.op = (require '../commands').commands
        text = fs.readFileSync './test/new-cgu-knet.txt', encoding:'utf8'
        (require 'assert') parser.parse text

      it 'should compile through flat-ornament', ->
        compile = require '../compile'
        text = fs.readFileSync './test/new-cgu-knet.txt', encoding:'utf8'
        {commands} = (require '../commands')
        (require 'assert') compile {language:'cgu-fr',script:text}, commands
