
Backbone = require "backbone"
_ = require "underscore"

ViewMaster = require "../vendor/backbone.viewmaster"
asEvents = require "../utils/asEvents"
i18n = require "../utils/i18n.coffee"

class LogoutAction extends ViewMaster

    className: "bb-logout-action"

    constructor: (opts) ->
        super
        @action = opts.action
        @timeout = opts.timeout || 50
        @updateInterval = opts.updateInterval || 1000
        @interval = null

        @cancel = _.once (e) =>
            @clearTimer()
            @trigger("close")

        @listenTo(asEvents(document), "click", @cancel)
        @listenTo(asEvents(document), "keyup", @cancel)
        @listenTo(asEvents(window), "blur", @cancel)

    events:
        "click .now": (e) ->
            @sendAction()

    template: require "../templates/LogoutAction.hbs"

    render: ->
        super
        @nowButton = @$(".now").get(0)
        @timerEl = @$(".timer-text").get(0)
        # console.log "FOO\n\n"
        # @$(".timer-text").css("top", "1")
        #console.log @$(".timer-text").position().top
        @startTimer()

    renderActionText: (count) ->
        @timerEl.innerText = i18n "logout.#{ @action }Action", {count}
        offset = $(@timerEl).offset()
        #$(@timerEl).offset()
        # offset = @timerEl.offset()
        # console.log offset.top
        # if offset.top > 0
        #     $(@timerEl).css("top", offset.top - 20)
        # console.log $(".timer-text").offset().top

    startTimer: ->
        timeout = @timeout
        timer = =>
            @renderActionText(timeout)
            if timeout <= 0
                @sendAction()
                return @clearTimer()
            timeout--

        timer()
        @interval = setInterval(timer, @updateInterval)

    remove: ->
        super
        @clearTimer()

    clearTimer: ->
        if @interval
            clearInterval(@interval)
            @interval = null

    sendAction: ->
        @bubble "logout-action", this
        @remove()

module.exports = LogoutAction


