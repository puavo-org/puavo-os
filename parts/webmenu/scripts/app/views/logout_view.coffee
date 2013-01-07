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
      localBoot: if @hostType is "thinclient" then false else true
    }

    events:
      "click .bb-logout": -> @bubble "logout"
      "click .bb-shutdown": -> @bubble "shutdown"
      "click .bb-reboot": -> @bubble "reboot"
      "click .bb-cancel": -> @bubble "cancel"

    constructor: (opts) ->
      super

      @hostType = opts.hostType
