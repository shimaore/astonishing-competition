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
        cdr.should.have.property 'rating_info'
        cdr.should.have.property 'integer_amount', 16
        cdr.should.have.property 'actual_amount', 0

      it 'should compile through get_plan_fun', ->
        compile = require '../compile'
        {get_plan_fun} = require '../get_plan_fun'
        doc =
          "_id": "plan:test_99"
          "plan": "test_99"
          "script":
            "language": "cgu-fr"
            "script": fs.readFileSync './test/new-cgu-knet.txt', encoding:'utf8'
            "label": "Pas cher"
        build_commands = require '../middleware/commands'
        commands = build_commands.call session: rated: params: {}

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
            rating:
              plan: 'test_99'
              table: 'any'
        expect fun = await get_plan_fun {get:-> await doc}, cdr, compile, commands
        cdr.compute 67

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
        cdr.should.have.property 'rating_info'
        cdr.should.have.property 'integer_amount', 10+(67-30)
        cdr.should.have.property 'actual_amount', 0

      it 'should compile through get_plan_fun (not-in numbering-plans)', ->
        compile = require '../compile'
        {get_plan_fun} = require '../get_plan_fun'
        doc =
          "_id": "plan:knet_188"
          "plan": "knet_188"
          "script":
            "language": "cgu-fr"
            "script": "Conformément à la réglementation, les appels d'urgences ne sont pas facturés.\n\nLes appels sur le réseau K-net sont inclus.\n\nLes appels vers les fixes en France métropolitaine sont inclus, dans la limite de 60 minutes par appel.\n\n\nLes appels vers les fixes en Allemagne, Argentine, Australie, Autriche, Belgique, Brésil, Chili, Chine, Chypre, Colombie, Danemark, Espagne, Estonie, Grèce, Hong-Kong, Hongrie, Irlande, Islande, Israël, Italie, Kazakhstan, Lettonie, Luxembourg, Malaisie, Mexique, Norvège, Nouvelle Zélande, Panama, Pays Bas, Pologne, Portugal, Pérou, Royaume-Uni, Russie, Singapour, Slovaquie, Suède, Suisse, Taïwan, Thaïlande, Vatican, et le Venezuela, sont inclus.\nLes appels vers les fixes et les mobiles aux USA, Canada, Guam, et les Iles Vierges (U.S.), sont inclus.\n"
            "label": "Pas cher"
        build_commands = require '../middleware/commands'
        commands = build_commands.call session: rated: params: {}

        cdr = new Rated
            billable_number: '33972121234'
            connect_stamp: '2020-01-13T18:29:42Z'
            remote_number: '351291221234'
            rating_data:
              initial:
                duration: 0
                cost: 0
              subsequent:
                duration: 1
                cost: 10
              country: 'pt'
              fixed: true
            per: 60
            divider: 100
            currency: 'EUR'
            vat_percent: 20
            rating:
              plan: 'knet_188'
              table: 'any'
        expect fun = await get_plan_fun {get:-> await doc}, cdr, compile, commands
        cdr.compute 3178

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
        cdr.should.have.property 'rating_info'
        cdr.should.have.property 'integer_amount', 530
        cdr.should.have.property 'actual_amount', 0


      it 'should compile through get_plan_fun (mobile)', ->
        compile = require '../compile'
        {get_plan_fun} = require '../get_plan_fun'
        doc =
          "_id": "plan:knet_99"
          "plan": "knet_99"
          "script":
            "language": "cgu-fr"
            "script": "Conformément à la réglementation, les appels d'urgences ne sont pas facturés.\n\nLes appels sur le réseau K-net sont inclus.\n\nLes appels vers les fixes en France métropolitaine sont inclus, dans la limite de 60 minutes par appel.\n\n\nLes appels vers les mobiles en France métropolitaine sont inclus, dans la limite de 99 destinataires, jusqu'à 15 heures par mois, dans la limite de 60 minutes par appel.\n\n\nLes appels vers les fixes en Allemagne, Argentine, Australie, Autriche, Belgique, Brésil, Chili, Chine, Chypre, Colombie, Danemark, Espagne, Estonie, Grèce, Hong-Kong, Hongrie, Irlande, Islande, Israël, Italie, Kazakhstan, Lettonie, Luxembourg, Malaisie, Mexique, Norvège, Nouvelle Zélande, Panama, Pays Bas, Pologne, Portugal, Pérou, Royaume-Uni, Russie, Singapour, Slovaquie, Suède, Suisse, Taïwan, Thaïlande, Vatican, et le Venezuela, sont inclus.\nLes appels vers les fixes et les mobiles aux USA, Canada, Guam, et les Iles Vierges (U.S.), sont inclus.\n"
            "label": "Pas cher"
        build_commands = require '../middleware/commands'
        commands = build_commands.call session: rated: params: {}

        cdr = new Rated
            billable_number: '33972121234'
            connect_stamp: '2020-01-15T18:29:42Z'
            remote_number: '33631151234'
            rating_data:
              initial:
                duration: 0
                cost: 0
              subsequent:
                duration: 1
                cost: 1
              country: 'fr'
              mobile: true
            per: 60
            divider: 100
            currency: 'EUR'
            vat_percent: 20
            rating:
              plan: 'knet_99'
              table: 'any'
        expect fun = await get_plan_fun {get:-> await doc}, cdr, compile, commands
        cdr.compute 620

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
        cdr.should.have.property 'rating_info'
        cdr.should.have.property 'integer_amount', 11
        cdr.should.have.property 'actual_amount', 0
