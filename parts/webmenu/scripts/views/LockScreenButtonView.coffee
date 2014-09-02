
ViewMaster = require "../vendor/backbone.viewmaster"

i18n = require "../utils/i18n.coffee"

class LockScreenButtonView extends ViewMaster

    className: "bb-menu-item type-hover-btn"

    template: require "../templates/MenuItemView.hbs"

    events:
        click: ->
            @bubble "lock-screen"

    context: ->
        osIconPath: "/usr/share/icons/Faenza/actions/96/system-lock-screen.png"
        name: i18n "logout.lock"

module.exports = LockScreenButtonView
