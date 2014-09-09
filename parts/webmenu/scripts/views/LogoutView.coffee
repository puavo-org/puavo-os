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
        actions = [ {
                      action: "logout",
                      class: "js-logout",
                      icon:  "/usr/share/icons/Faenza/actions/24/system-log-out.png",
                      text:  "logout.logout"
                    } ]

        if not @config.get("webkioskMode")
            if not @config.get("guestSession")
                actions.unshift( {
                    action: "lock",
                    class: "js-lock",
                    icon:  "/usr/share/icons/Faenza/actions/24/lock.png",
                    text:  "logout.lock"
                } )

          actions.push( {
              action: "restart",
              class: "js-restart",
              icon:  "/usr/share/icons/Faenza/apps/24/system-restart.png",
              text:  "logout.restart"
          },
          {
              action: "shutdown",
              class: "js-shutdown",
              icon:  "/usr/share/icons/Faenza/actions/24/system-shutdown-panel.png",
              text:  "logout.shutdown"
          } )

          if @config.get("hostType") is "laptop"
              actions.push( {
                  action: "sleep",
                  class: "js-sleep",
                  icon:  "/usr/share/icons/Faenza/apps/24/system-suspend.png",
                  text:  "logout.sleep"
              } )
        return {
            actions: actions
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
