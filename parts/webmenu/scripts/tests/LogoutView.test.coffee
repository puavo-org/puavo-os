Q = require "q"
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

    afterEach -> @view.remove()

    describe "for laptop", ->
        beforeEach createLogoutView("laptop")

        it "has hibernate", -> assert "hibernate" in @options
        it "has sleep", -> assert "sleep" in @options
        it "has restart", -> assert "restart" in @options
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
        it "has restart", -> assert "restart" in @options
        it "has lock", -> assert "lock" in @options

        it "bubbles logout-action with feedback", (done) ->
            @view.on "logout-action", (actionView) ->
                assert.equal actionView.action, "shutdown"
                assert not actionView.model.hasFeedback()
                done()
            @view.$(".js-shutdown").trigger "click"
            setTimeout =>
                @view.$(".now").trigger "click"
            , 1

        it "removes logout action view on cancel", (done) ->
            Backbone.$("body").append(@view.el)

            @view.$(".js-shutdown").trigger "click"

            Q.delay(10)
            .then =>
                assert.equal @view.$(".now").size(), 1
                # "click anywhere cancel"
                @view.$(".bb-logout-action").trigger "click"
                Q.delay(10)
            .then =>
                assert.equal @view.$(".now").size(), 0
            .done(done)
