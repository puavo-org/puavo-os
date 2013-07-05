Backbone = require "backbone"
ViewMaster = require "../vendor/backbone.viewmaster"

LogoutAction = require "./LogoutAction.coffee"
i18n = require "../utils/i18n.coffee"

class LogoutView extends ViewMaster

    className: "bb-logout-view"

    constructor: (opts) ->
        super
        @hostType = opts.hostType

    template: require "../templates/LogoutView.hbs"

    context: ->
        actions = ["lock", "reboot"]
        if @hostType is "laptop"
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
            # return if e.target.value is "or"
            @displayAction(e.target.value)

    displayAction: (action) -> setTimeout =>
        @$(".logout-btn-container").empty()
        actionView = new LogoutAction action: action
        @setView ".logout-btn-container", actionView
        @refreshViews()
        actionView.on "close", =>
            actionView.remove()
            @render()
        , 1000
    , 0 # Workaround immediate click trigger


module.exports = LogoutView
