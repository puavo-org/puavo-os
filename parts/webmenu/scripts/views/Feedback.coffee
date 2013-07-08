
_ = require "underscore"
ViewMaster = require "../vendor/backbone.viewmaster"

asEvents = require "../utils/asEvents"
renderTextarea = require "../templates/FeedbackMessage.hbs"
renderMood = require "../templates/FeedbackMood.hbs"

moodResponses =
    good: "Glad to hear! If you want to send any other feedback just write it here and we'll read it!"
    bad: "Ok, frowny face it is :( \nIf you wish - you may write here what bothered you so we can fix it!"


class Feedback extends ViewMaster

    className: "bb-feedback"

    template: require "../templates/Feedback.hbs"

    constructor: ->
        super
        @listenTo @model, "change", @render, this
        @listenTo asEvents(window), "blur", =>
            if @$textarea
                @model.set(message: @$textarea.val())

    afterTemplate: ->
        question = @$(".question-container")

        if @model.get "saved"
            question.text "Thanks! Your feedback has been sent."
        else if @model.get("mood")
            question.html renderTextarea(
                moodResponse: moodResponses[@model.get("mood")]
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
