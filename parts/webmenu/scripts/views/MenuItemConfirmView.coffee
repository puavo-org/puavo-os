Backbone = require "backbone"
ViewMaster = require "../vendor/backbone.viewmaster"

i18n = require "../utils/i18n.coffee"

class MenuItemConfirmView extends ViewMaster

    className: "bb-menu-item-confirm"

    constructor: (opts) ->
        super
        @config = opts.config
        @timeout = opts.timeout || 50
        @updateInterval = opts.updateInterval || 1000
        @interval = null


    template: require "../templates/MenuItemConfirmView.hbs"

#    context: ->

    render: ->
        super
        @timerEl = @$(".timer-text").get(0)
        @startTimer()


    renderConfirmText: (count) ->
        @timerEl.innerText = "Tietokone sammutetaan #{ count } sekunnin kuluttua..." #i18n "logout.#{ @action }Action", {count}


    startTimer: ->
        timeout = @timeout
        timer = =>
            @renderConfirmText(timeout)
            if timeout <= 0
                @sendAction() # FIXME
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
        "click .js-lock": (e) ->
            #@displayAction("lock")
            console.log("CLICK")
        "close": ->
            console.log("CLOSE")


module.exports = MenuItemConfirmView
