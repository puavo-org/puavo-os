
LogoutView = require "../views/LogoutView.coffee"

assert = require "assert"

describe "LogoutView", ->

    describe "for laptop", ->
        beforeEach ->
            @view = new LogoutView
                hostType: "laptop"
            @view.render()
            @options = @view.$("option").map (i, el) ->
                el.value

        it "shutdown button opens shutdown timer", (done) ->
            @view.$(".js-shutdown").trigger "click"
            setTimeout =>
                assert.equal @view.$(".bb-logout-action").size(), 1
                done()
            , 5

        it "has hibernate", -> assert "hibernate" in @options
        it "has sleep", -> assert "sleep" in @options
        it "has reboot", -> assert "reboot" in @options
        it "has lock", -> assert "lock" in @options


    describe "for thinclient", ->
        beforeEach ->
            @view = new LogoutView
                hostType: "thinclient"
            @view.render()
            @options = @view.$("option").map (i, el) ->
                el.value

        it "has no hibernate", -> assert not ("hibernate" in @options)
        it "has no sleep", -> assert not ("sleep" in @options)
        it "has reboot", -> assert "reboot" in @options
        it "has lock", -> assert "lock" in @options
