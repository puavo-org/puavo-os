
ViewMaster = require "../vendor/backbone.viewmaster"

i18n = require "../utils/i18n.coffee"

class LogoutButtonView extends ViewMaster

    className: "bb-menu-item type-hover-btn"

    template: require "../templates/MenuItemView.hbs"

    events:
        "click": ->
            @bubble "open-logout-view"

    context: ->
        "osIconPath": "/usr/share/icons/Faenza/actions/96/system-shutdown.png"
        name: i18n "logout.exit"

module.exports = LogoutButtonView
