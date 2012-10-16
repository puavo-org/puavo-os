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
      "click .bb-logout": -> Application.trigger "logout"
      "click .bb-shutdown": -> Application.trigger "shutdown"
      "click .bb-reboot": -> Application.trigger "reboot"
