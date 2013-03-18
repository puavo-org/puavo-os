define [
  "backbone.viewmaster"

  "cs!app/views/lightbox_view"
  "cs!app/views/logout_view"
  "cs!app/utils/i18n"
  "hbs!app/templates/menuitem"
], (
  ViewMaster

  Lightbox
  LogoutView
  i18n
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
      name: i18n "logout.exit"
