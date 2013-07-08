
Backbone = require "backbone"

# We will send mood feedback always, but message only if user clicked save from
# the form.
class FeedbackModel extends Backbone.Model

    haveFeedback: -> !! @get "mood"

    toJSON: ->
        ob = mood: @get "mood"
        if @get "saved"
            ob.message = @get "message"
        ob

module.exports = FeedbackModel
