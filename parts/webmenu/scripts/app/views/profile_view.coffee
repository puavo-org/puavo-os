define [
  "backbone.viewmaster"

  "hbs!app/templates/profile"
  "cs!app/application"
  "cs!app/views/logout_view"
  "cs!app/views/lightbox_view"
], (
  ViewMaster

  template
  Application
  LogoutView
  Lightbox
) ->

  class ProfileView extends ViewMaster

    className: "bb-profile"

    template: template

    events:
      "click .bb-profile-settings": (e) ->
        Application.bridge.trigger "open", @config.get("profileCMD")
      "click .bb-change-password": (e) ->
        Application.bridge.trigger "open", @config.get("passwordCMD")
      "click .bb-settings": (e) ->
        Application.bridge.trigger "open", @config.get("settingsCMD")
      "click .bb-logout": (e) ->

        @lb = new Lightbox
          view: new LogoutView
        @lb.render()

    constructor: (opts) ->
      super
      @config = opts.config
      @listenTo Application.global, "show", =>
        @lb?.remove()

    context: -> {
      user: @model.toJSON()
      config: @config.toJSON()
    }

    remove: ->
      @lb?.remove()
      super
