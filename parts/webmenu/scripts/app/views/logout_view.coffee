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
      "click .js-logout": -> Backbone.trigger "logout"
      "click .js-shutdown": -> Backbone.trigger "shutdown"
      "click .js-reboot": -> Backbone.trigger "reboot"
      "click .js-lock": -> Backbone.trigger "lock"
      "click .js-cancel": -> @bubble "cancel"

    constructor: (opts) ->
      super

      @hostType = opts.hostType
