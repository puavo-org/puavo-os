
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
        @timeout = opts.timeout || 5
        @updateInterval = opts.updateInterval || 1000
        @interval = null

        @cancel = _.once (e) =>
            @clearTimer()
            if e?.target is @nowButton
                @sendAction()
            else
                @trigger("cancel")

        @listenTo(asEvents(document), "click", @cancel)
        @listenTo(asEvents(document), "keyup", @cancel)
        @listenTo(asEvents(window), "blur", @cancel)

    template: require "../templates/LogoutAction.hbs"

    render: ->
        super
        @nowButton = @$(".now").get(0)
        @timerEl = @$(".timer-text").get(0)
        @startTimer()

    renderActionText: (count) ->
        @timerEl.innerText = i18n "logout.#{ @action }Action", {count}

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
        @bubble "logout-action", @action

module.exports = LogoutAction


