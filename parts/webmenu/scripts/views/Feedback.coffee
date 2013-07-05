
ViewMaster = require "../vendor/backbone.viewmaster"



class Feedback extends ViewMaster

    className: "bb-feedback"

    template: require "../templates/Feedback.hbs"

    events:
        "click .bad": ->
            msg = "Ok, frowny face it is :( \nIf you wish - you may write here what bothered you so we can fix it!"
            @displayTextbox(msg)
        "click .good": ->
            msg = "Glad to hear! If you want to send any other feedback just write it here and we'll read it!"
            @displayTextbox(msg)

    msg: (msg) ->

    displayTextbox: (msg) ->
        @$textarea.prop("placeholder", msg)
        @$mood.hide()
        @$textbox.show()
        @$message.hide()

    render: ->
        super
        @$mood = @$(".mood")
        @$message = @$(".message")
        @$textbox = @$(".textbox")
        @$textarea = @$(".textbox textarea")

module.exports = Feedback

