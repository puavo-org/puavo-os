define [
  "backbone.viewmaster"

  "cs!app/views/lightbox_view"
  "cs!app/views/logout_view"
  "hbs!app/templates/menuitem"
], (
  ViewMaster

  Lightbox
  LogoutView
  menuItemTemplate
) ->

  class LogoutButtonView extends ViewMaster

    className: "bb-menu-item"

    template: menuItemTemplate

    events:
      "click": ->
        @bubble "open-logout-view"

    context: ->
      cssIcon: "icon-logout"
      name: "Kirjaudu ulos"
