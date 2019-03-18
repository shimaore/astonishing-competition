    ({expect} = require 'chai').should()
    fs = require 'fs'
    Rated = require 'entertaining-crib/rated'
    describe 'The CGU', ->
      it 'should compile', ->
        {Parser} = require '../cgu-fr'
        parser = new Parser()
        name = 0
        parser.yy.new_name = -> "name#{name++}"
        parser.yy.op = (require '../commands').commands
        text = fs.readFileSync './test/new-cgu-knet.txt', encoding:'utf8'
        expect parser.parse text

      it 'should compile through flat-ornament', ->
        compile = require '../compile'
        text = fs.readFileSync './test/new-cgu-knet.txt', encoding:'utf8'
        build_commands = require '../middleware/commands'
        commands = build_commands.call session: rated: params: {}

        expect fun = compile {language:'cgu-fr',script:text}, commands
        cdr = new Rated
            billable_number: '42'
            connect_stamp: '2018-10-31T18:29:42Z'
            remote_number: '33643482771'
            rating_data:
              initial:
                duration: 30
                cost: 10
              subsequent:
                duration: 1
                cost: 1
            per: 1
            divider: 100
        cdr.compute 36

        ctx = {
          cdr
          update_counter: (name,value,expire) ->
            console.log 'update_counter', {name,value,expire}
            [true,42]
          get_counter: (name) ->
            console.log 'get counter', name
            [true,42]
        }
        await fun.call ctx
        console.log cdr
        cdr.should.have.property 'rating_info'
        cdr.should.have.property 'integer_amount', 16
        cdr.should.have.property 'actual_amount', 0
