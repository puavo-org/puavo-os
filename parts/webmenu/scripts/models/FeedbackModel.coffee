
Backbone = require "backbone"
Q = require "q"

# We will send mood feedback always, but message only if user clicked save from
# the form.
class FeedbackModel extends Backbone.Model


    hasFeedback: -> !! @get "mood"

    toJSON: ->
        ob = mood: @get "mood"
        if @get "saved"
            ob.message = @get "message"
        ob

    clear: ->
        super
        @sending = null

    send: (options) ->
        return @sending if @sending
        return Q.reject("no feedback") if not @hasFeedback()
        @sending = window.nodejs.sendFeedback(@toJSON())
        .fail (err) ->
            console.error "Failed to send feedback: #{ err.message }"
        .finally => @clear(options)


module.exports = FeedbackModel
