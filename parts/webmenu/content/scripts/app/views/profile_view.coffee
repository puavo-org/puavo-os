define [
  "cs!app/view"
  "hbs!app/templates/profile"
  "cs!app/application"
  "cs!app/views/logout_view"
  "cs!app/views/lightbox_view"
], (
  View
  template
  Application
  LogoutView
  Lightbox
) ->

  class ProfileView extends View

    className: "bb-profile"

    template: template

    events:
      "click .bb-profile-settings": (e) ->
        Application.bridge.send "showMyProfileWindow"
      "click .bb-change-password": (e) ->
        Application.bridge.send "showChangePasswordWindow"
      "click .bb-settings": (e) ->
        Application.bridge.send "openSettings"
      "click .bb-logout": (e) ->

        @lb = new Lightbox
          view: new LogoutView
        @lb.render()

    constructor: (opts) ->
      super
      @config = opts.config
      @bindTo Application.global, "show", =>
        @lb?.remove()

    viewJSON: -> {
      user: @model.toJSON()
      config: @config.toJSON()
    }

    remove: ->
      @lb?.remove()
      super
