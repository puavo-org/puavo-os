
_ = require "underscore"
ViewMaster = require "../vendor/backbone.viewmaster"

i18n = require "../utils/i18n.coffee"
asEvents = require "../utils/asEvents"
renderTextarea = require "../templates/FeedbackMessage.hbs"
renderMood = require "../templates/FeedbackMood.hbs"

class Feedback extends ViewMaster

    className: "bb-feedback"

    template: require "../templates/Feedback.hbs"

    constructor: ->
        super
        @listenTo @model, "change", @render, this
        @listenTo @model, "start-sending", @render, this

    persistMessage: ->
        if @$textarea
            @model.set({message: @$textarea.val()}, {silent: true})

    afterTemplate: ->
        question = @$(".question-container")

        if @model.sending
            question.text i18n "logout.sending"
            @model.sending.then =>
                question.text i18n "feedback.thanks"
            , =>
                question.text i18n "logout.sendingFailed"
        else if @model.get("mood")
            question.html renderTextarea(
                moodResponse: i18n "feedback.#{ [@model.get("mood")] }"
                message: @model.get("message")
            )
            @$textarea = @$("textarea")
        else
            question.html renderMood()


    events:
        "keyup": "persistMessage"
        "click .bad": -> @model.set "mood", "bad"
        "click .good": -> @model.set "mood", "good"
        "click .save": ->
            @model.set(
                message: @$textarea.val(),
                silent: true
            )
            @model.send()

module.exports = Feedback
