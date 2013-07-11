assert = require "assert"

ViewMaster = require "../vendor/backbone.viewmaster"
Backbone = require "backbone"

MenuItemView = require "../views/MenuItemView.coffee"
MenuModel = require "../models/MenuModel.coffee"


describe "MenuItemView", ->

    beforeEach ->
        @parent = new ViewMaster
        @parent.template = -> "<div class=container></div>"

        model = new MenuModel
            name: "Test menu"
            type: "menu"
            items: [
                name: "Test item"
                type: "custom"
                command: "testcmd"
            ]

        @item = new MenuItemView
            model: model.items.first()

        @parent.appendView(".container", @item)
        @parent.render()

    afterEach ->
        @item.remove()
        @parent.remove()

    it "MenuItemView#open() bubbles 'app-open' events only once in 250ms", (done) ->

        spy = chai.spy()
        @parent.on "open-app", spy

        @item.open()
        setTimeout =>
            @item.open()
            expect(spy).to.have.been.called.once
            done()
        , 20

    it "MenuItemView#open() bubbles 'app-open' events twice in 300ms", (done) ->

        spy = chai.spy()
        @parent.on "open-app", spy

        @item.open()
        setTimeout =>
            @item.open()
            expect(spy).to.have.been.called.twice
            done()
        , 300

    describe "click count", ->

        beforeEach ->
            @item.$el.trigger "click"

        it "increases after a click", ->
            assert false
            # assert.equal @item.model.get("clicks"), 1


