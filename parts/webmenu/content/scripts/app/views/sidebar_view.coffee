define [
  "cs!app/view"
  "hbs!app/templates/sidebar"
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

  class SidebarView extends View

    className: "sidebar-container"

    template: template

    events:
      "click .bb-profile": (e) ->
        Application.trigger "showMyProfileWindow"
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
