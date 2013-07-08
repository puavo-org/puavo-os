
Backbone = require "backbone"
LogoutView = require "../views/LogoutView.coffee"
FeedbackModel = require "../models/FeedbackModel.coffee"

assert = require "assert"

describe "LogoutView", ->

    createLogoutView = (type) -> ->
        @view = new LogoutView
            model: new FeedbackModel
            config: new Backbone.Model
                feedback: "send-feedback-command"
                hostType: type
        @view.render()
        @options = @view.$("option").map (i, el) ->
            el.value

    describe "for laptop", ->
        beforeEach createLogoutView("laptop")

        it "has hibernate", -> assert "hibernate" in @options
        it "has sleep", -> assert "sleep" in @options
        it "has reboot", -> assert "reboot" in @options
        it "has lock", -> assert "lock" in @options
        it "shutdown button opens shutdown timer", (done) ->
            @view.$(".js-shutdown").trigger "click"
            setTimeout =>
                assert.equal @view.$(".bb-logout-action").size(), 1
                done()
            , 5

    describe "for thinclient", ->
        beforeEach createLogoutView("thinclient")

        it "has no hibernate", -> assert not ("hibernate" in @options)
        it "has no sleep", -> assert not ("sleep" in @options)
        it "has reboot", -> assert "reboot" in @options
        it "has lock", -> assert "lock" in @options
