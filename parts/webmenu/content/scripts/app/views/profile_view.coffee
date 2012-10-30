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
        Application.trigger "showMyProfileWindow"
      "click .bb-change-password": (e) ->
        Application.trigger "showChangePasswordWindow"
      "click .bb-settings": (e) ->
        Application.trigger "openSettings"
      "click .bb-logout": (e) ->

        @lb = new Lightbox
          view: new LogoutView
        @lb.render()

    constructor: ->
      super
      @bindTo Application, "show", =>
        @lb?.remove()

    remove: ->
      @lb?.remove()
      super
