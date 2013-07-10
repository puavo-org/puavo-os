Backbone = require "backbone"
Q = require "q"

Feedback = require "../views/Feedback.coffee"
FeedbackModel = require "../models/FeedbackModel.coffee"

FeedbackModel._sendFeedBack = -> Q()

assert = require "assert"

describe "Feedback", ->

    beforeEach ->
        @model = new FeedbackModel
        @view = new Feedback model: @model
        @view.render()

    afterEach -> @view.remove()

    describe "mood button", ->

        it "for good sets good mood", (done) ->
            @model.on "change", =>
                assert.equal @model.get("mood"), "good"
                done()
            @view.$(".good").trigger "click"

        it "for bad sets good bad", (done) ->
            @model.on "change", =>
                assert.equal @model.get("mood"), "bad"
                done()
            @view.$(".bad").trigger "click"

        [".good", ".bad"].forEach (sel) ->

            it "from #{ sel } displays textarea", ->
                @view.$(sel).trigger "click"
                assert @view.$("textarea").size()

    describe "message", ->
        beforeEach ->
            @view.$(".good").trigger "click"

        it "save button sets message with on change event", (done) ->
            @model.on "change", =>
                assert.equal @model.get("message"), "foobar"
                done()
            @view.$("textarea").val("foobar")
            @view.$(".save").trigger "click"

