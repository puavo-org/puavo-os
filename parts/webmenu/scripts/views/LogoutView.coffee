Backbone = require "backbone"
ViewMaster = require "../vendor/backbone.viewmaster"

LogoutAction = require "./LogoutAction.coffee"

class LogoutView extends ViewMaster

    className: "bb-logout-view"

    template: require "../templates/LogoutView.hbs"

    context: -> {
        localBoot: @hostType isnt "thinclient"
    }

    events:
        "click .js-shutdown": -> @displayAction("shutdown")
        "click .js-logout": -> @displayAction("logout")
        "change select": (e) ->
            @displayAction(e.target.value)

    displayAction: (action) -> setTimeout =>
        @$(".logout-btn-container").empty()
        actionView = new LogoutAction action: action
        @setView ".logout-btn-container", actionView
        @refreshViews()
        actionView.on "cancel", =>
            actionView.remove()
            @render()
        , 1000
    , 0 # Workaround immediate click trigger

    constructor: (opts) ->
        super

        @hostType = opts.hostType

module.exports = LogoutView
