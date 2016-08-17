
_ = require "underscore"
ViewMaster = require "../vendor/backbone.viewmaster"

i18n = require "../utils/i18n.coffee"
asEvents = require "../utils/asEvents"
renderTextarea = require "../templates/FeedbackMessage.hbs"

class Feedback extends ViewMaster
    MOODS = ["very-good", "good", "bad", "very-bad"]

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

    context: ->
        moods = MOODS.map (mood) =>
            cssClass = mood

            if @model.get("mood")
                if mood == @model.get("mood")
                    cssClass += " selected"
                else
                    cssClass += " unselected"

            return {
                cssClass: cssClass,
                imagePath: "styles/theme/default/img/#{ mood }.png"
            }

        return {
            moods: moods
        }


    events:
        "keyup": "persistMessage"
        "click .very-good": (e) ->
            return if @model.get("hasSendFeedback")
            @model.set "mood", "very-good"
        "click .good": (e) ->
            return if @model.get("hasSendFeedback")
            @model.set "mood", "good"
        "click .bad": (e) ->
            return if @model.get("hasSendFeedback")
            @model.set "mood", "bad"
        "click .very-bad": (e) ->
            return if @model.get("hasSendFeedback")
            @model.set "mood", "very-bad"
        "click .cancel": ->
            @model.set "mood", null
            @$textarea.val("")
        "click .save": ->
            @model.set(
                message: @$textarea.val(),
                silent: true,
                hasSendFeedback: true
            )
            @model.send()

module.exports = Feedback
