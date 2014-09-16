
Backbone = require "backbone"
Q = require "q"

# We will send mood feedback always, but message only if user clicked save from
# the form.
class FeedbackModel extends Backbone.Model

    FeedbackModel._sendFeedBack = window.nodejs?.sendFeedback

    hasFeedback: -> !! @get "mood"

    clear: ->
        super
        @sending = null

    send: ->
        return @sending if @sending
        return Q.reject("no feedback") if not @hasFeedback()
        @sending = FeedbackModel._sendFeedBack(@toJSON())
        @trigger "start-sending"
        return @sending


module.exports = FeedbackModel
