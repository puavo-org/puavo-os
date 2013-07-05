
Backbone = require "backbone"
_ = require "underscore"

ViewMaster = require "../vendor/backbone.viewmaster"
asEvents = require "../utils/asEvents"
i18n = require "../utils/i18n.coffee"

ACTIONS =
    shutdown:
        name: "Shutdown"
        description: (count) -> i18n "logout.shutdownAction", {count}
    logout:
        name: "Logout"
        description: (count) -> i18n "logout.logoutAction", {count}
    reboot:
        name: "Reboot"
        description: (count) -> i18n "logout.rebootAction", {count}
    sleep:
        name: "Sleep"
        description: (count) -> i18n "logout.sleepAction", {count}
    hibernate:
        name: "Hibernate"
        description: (count) -> i18n "logout.hibernateAction", {count}

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

    context: -> {
        action: ACTIONS[@action]
    }

    template: require "../templates/LogoutAction.hbs"

    render: ->
        super
        @startTimer()

    startTimer: ->
        el = @$(".timer-text").get(0)
        @nowButton = @$(".now").get(0)
        timeout = @timeout
        draw = =>
            el.innerText = ACTIONS[@action].description(timeout)
            if timeout <= 0
                @sendAction()
                return @clearTimer()
            timeout--

        draw()
        @interval = setInterval(draw, @updateInterval)

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


