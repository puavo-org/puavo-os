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

    className: "bb-menu-item type-hover-btn"

    template: menuItemTemplate

    events:
      "click": ->
        @bubble "open-logout-view"

    context: ->
      "osIconPath": "/usr/share/icons/Faenza/actions/96/system-shutdown.png"
      name: "Kirjaudu ulos"
