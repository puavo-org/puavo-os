
LogoutAction = require "../views/LogoutAction.coffee"

assert = require "assert"

describe "LogoutAction", ->

    view = null
    beforeEach ->
        view = new LogoutAction
            action: "logout"
            timeout: 5
            updateInterval: 10

    it "emits logout-action event after timeout", (done) ->
        view.once "logout-action", (action) ->
            assert.equal action, "logout"
            done()

        view.render()

    it "logout-action can be canceled with view.cancel()", (done) ->
        view.on "logout-action", (action) ->
            done(new Error "action was not canceled")

        view.on "close", -> done()

        view.render()
        setTimeout ->
            view.cancel()
        , 1

    it "timer text gets updated", (done) ->
        view.render()
        first = view.$(".timer-text").text()
        setTimeout ->
            assert.notEqual first, view.$(".timer-text").text()
            done()
        , 21
