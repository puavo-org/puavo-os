define [
  "cs!app/view"
  "hbs!app/templates/logout"
  "cs!app/application"
], (
  View
  template
  Application
) ->
  class LogoutView extends View

    template: template

    viewJSON: -> {
      fatClient: true
    }

    events:
      "click .bb-logout": -> Application.bridge.send "logout"
      "click .bb-shutdown": -> Application.bridge.send "shutdown"
      "click .bb-reboot": -> Application.bridge.send "reboot"
