Backbone = require "backbone"
ViewMaster = require "../vendor/backbone.viewmaster"

LogoutAction = require "./LogoutAction.coffee"
Feedback = require "./Feedback.coffee"
i18n = require "../utils/i18n.coffee"

class LogoutView extends ViewMaster

    className: "bb-logout-view"

    constructor: (opts) ->
        super
        @config = opts.config
        if @config.get("feedback")
            @setView ".feedback-container", Feedback

    template: require "../templates/LogoutView.hbs"

    context: ->
        actions = ["lock", "reboot"]
        if @config.get("hostType") is "laptop"
            actions.unshift "hibernate"
            actions.unshift "sleep"
        return actions: actions.map (a) -> {
            value: a
            name: i18n "logout.#{ a }"
        }

    events:
        "click .js-shutdown": -> @displayAction("shutdown")
        "click .js-logout": -> @displayAction("logout")
        "change select": (e) ->
            # TODO
            # return if e.target.value is "or"
            @displayAction(e.target.value)

    displayAction: (action) -> setTimeout =>
        @$(".logout-btn-container").empty()
        actionView = new LogoutAction
            action: action
            model: @model

        actionView.on "close", =>
            actionView.remove()
            @render()
        , 1000

        @setView ".logout-btn-container", actionView
        @refreshViews()

    , 0 # Workaround immediate click trigger


module.exports = LogoutView
