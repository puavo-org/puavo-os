Backbone = require "backbone"
ViewMaster = require "../vendor/backbone.viewmaster"

class LogoutView extends ViewMaster

    template: require "../templates/LogoutView.hbs"

    context: -> {
        localBoot: @hostType isnt "thinclient"
    }

    events:
        "click .js-logout": -> Backbone.trigger "logout"
        "click .js-shutdown": -> Backbone.trigger "shutdown"
        "click .js-reboot": -> Backbone.trigger "reboot"
        "click .js-lock": -> Backbone.trigger "lock"

    constructor: (opts) ->
        super

        @hostType = opts.hostType

module.exports = LogoutView
