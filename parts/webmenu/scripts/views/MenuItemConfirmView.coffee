Backbone = require "backbone"
ViewMaster = require "../vendor/backbone.viewmaster"

i18n = require "../utils/i18n.coffee"

class MenuItemConfirmView extends ViewMaster

    className: "bb-menu-item-confirm"

    constructor: (opts) ->
        super
        @config = opts.config
        @timeout = opts.timeout || 5
        @updateInterval = opts.updateInterval || 1000
        @interval = null
        @listenTo this, "hide-window", =>
            @clearTimer()


    template: require "../templates/MenuItemConfirmView.hbs"

    render: ->
        super
        @timerEl = @$(".timer-text").get(0)
        @startTimer()


    renderConfirmText: (count) ->
        @timerEl.innerText = i18n @model.get("confirmText"), {count}


    startTimer: ->
        timeout = @timeout
        timer = =>
            @renderConfirmText(timeout)
            if timeout <= 0
                console.log("TIMEOUT, run command")
                @bubble "open-app", @model
                @remove()
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


    events:
        "click .cancel": (e) ->
            @bubble "cancel"
        "click .ok": (e) ->
            @bubble "open-app", @model


module.exports = MenuItemConfirmView
