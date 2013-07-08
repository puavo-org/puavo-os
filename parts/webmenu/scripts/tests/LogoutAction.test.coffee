
Backbone = require "backbone"
LogoutAction = require "../views/LogoutAction.coffee"

assert = require "assert"

describe "LogoutAction", ->

    beforeEach ->
        @view = new LogoutAction
            action: "logout"
            timeout: 5
            updateInterval: 10

    afterEach -> @view.remove()

    it "emits logout-action event after timeout", (done) ->
        @view.once "logout-action", (action) ->
            assert.equal action, "logout"
            done()

        @view.render()

    it "logout-action can be canceled with view.cancel()", (done) ->
        @view.on "logout-action", (action) ->
            done(new Error "action was not canceled")

        @view.on "close", -> done()

        @view.render()
        setTimeout =>
            @view.cancel()
        , 1

    it "timer text gets updated", (done) ->
        @view.render()
        first = @view.$(".timer-text").text()
        setTimeout =>
            assert.notEqual first, @view.$(".timer-text").text()
            done()
        , 21

    it "can be executed immediately from now", (done) ->
        @view = new LogoutAction action: "logout"
        @view.render()
        @view.on "logout-action", (action) ->
            assert.equal action, "logout"
            done()
        @view.$(".now").trigger "click"


    it "can be canceled by clicking anything", (done) ->
        @view = new LogoutAction action: "logout"

        # Add to DOM tree so events can bubble up to document element
        Backbone.$("body").append(@view.el)

        @view.render()
        @view.on "logout-action", (action) ->
            done(new Error "should not trigger logout-action")
        @view.on "close", ->
            done()

        @view.$el.trigger("click")
