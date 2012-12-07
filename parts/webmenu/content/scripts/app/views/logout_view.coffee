define [
  "backbone.viewmaster"

  "hbs!app/templates/logout"
  "cs!app/application"
], (
  ViewMaster

  template
  Application
) ->
  class LogoutView extends ViewMaster

    template: template

    context: -> {
      fatClient: true
    }

    events:
      "click .bb-logout": -> Application.bridge.trigger "logout"
      "click .bb-shutdown": -> Application.bridge.trigger "shutdown"
      "click .bb-reboot": -> Application.bridge.trigger "reboot"
