
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
        @listenTo asEvents(window), "blur", @onBlur, this

    onBlur: ->
        if @$textarea
            @model.set(message: @$textarea.val())

    afterTemplate: ->
        question = @$(".question-container")

        if @model.get "saved"
            question.text i18n "feedback.thanks"
        else if @model.get("mood")
            question.html renderTextarea(
                moodResponse: i18n "feedback.#{ [@model.get("mood")] }"
                message: @model.get("message")
            )
            @$textarea = @$("textarea")
        else
            question.html renderMood()


    events:
        "click .bad": ->
            @model.set "mood", "bad"
        "click .good": ->
            @model.set "mood", "good"
        "click .save": ->
            @model.set(
                saved: true
                message: @$textarea.val()
            )
            @bubble "send-feedback", @model


module.exports = Feedback
