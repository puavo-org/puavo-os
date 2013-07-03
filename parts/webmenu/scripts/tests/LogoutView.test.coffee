Backbone = require "backbone"

Application = require "../Application.coffee"
LogoutView = require "../views/LogoutView.coffee"
Lightbox = require "../views/Lightbox.coffee"

describe "LogoutView", ->
    view = null
    beforeEach ->
        Application.reset()
        view = new LogoutView
            hostType: "fatclient"
        view.render()
    afterEach ->
        view.remove()

    describe "logout button", ->
        it "emits logout event", (done) ->
            Backbone.once "logout", -> done()
            view.$(".js-logout").click()

    describe "shutdown button", ->
        it "emits shutdown event", (done) ->
            Backbone.once "shutdown", -> done()
            view.$(".js-shutdown").click()

    describe "reboot button", ->
        it "emits reboot event", (done) ->
            Backbone.once "reboot", -> done()
            view.$(".js-reboot").click()

