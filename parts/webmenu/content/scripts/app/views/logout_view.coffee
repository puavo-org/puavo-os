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
      "click .bb-logout": -> Application.bridge.send "logout"
      "click .bb-shutdown": -> Application.bridge.send "shutdown"
      "click .bb-reboot": -> Application.bridge.send "reboot"
