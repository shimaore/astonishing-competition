    fs = require 'fs'
    describe 'The menu', ->
      it 'should compile', ->
        {Parser} = require '../language'
        parser = new Parser()
        parser.yy.op =
          clear_call_center_tags: true
          clear_user_tags: true
          user_tag: true
          required_skill: true
          alert_info: true
          queue: true
          send: true
          in_calendars: true
          goto_menu: true
        text = fs.readFileSync './test/test.menu', encoding:'utf8'
        (require 'assert') parser.parse text

    describe 'The CGU', ->
      it 'should compile', ->
        {Parser} = require '../language'
        parser = new Parser()
        name = 0
        parser.yy.new_name = -> "name#{name++}"
        text = fs.readFileSync './test/new-cgu-knet.txt', encoding:'utf8'
        (require 'assert') parser.parse text
        console.log JSON.stringify (parser.parse text), null, '  '
