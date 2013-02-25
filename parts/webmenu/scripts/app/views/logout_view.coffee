define [
  "backbone"
  "backbone.viewmaster"

  "hbs!app/templates/logout"
  "cs!app/application"
], (
  Backbone
  ViewMaster

  template
  Application
) ->
  class LogoutView extends ViewMaster

    template: template

    context: -> {
      localBoot: @hostType isnt "thinclient"
    }

    events:
      "click .bb-logout": -> Backbone.trigger "logout"
      "click .bb-shutdown": -> Backbone.trigger "shutdown"
      "click .bb-reboot": -> Backbone.trigger "reboot"
      "click .bb-cancel": -> Backbone.trigger "cancel"

    constructor: (opts) ->
      super

      @hostType = opts.hostType
