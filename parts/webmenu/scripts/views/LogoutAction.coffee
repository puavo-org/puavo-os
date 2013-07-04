
Backbone = require "backbone"
_ = require "underscore"

ViewMaster = require "../vendor/backbone.viewmaster"
asEvents = require "../utils/asEvents"

ACTIONS =
    shutdown:
        name: "Shutdown"
        description: "Computer will be shutdown"
    logout:
        name: "Logout"
        description: "You will be logged out"
    reboot:
        name: "Reboot"
        description: "Computer will be rebooted"
    sleep:
        name: "Sleep"
        description: "Computer will be put to sleep"
    hibernate:
        name: "Hibernate"
        description: "Computer will hibernated"

class LogoutAction extends ViewMaster


    constructor: (opts) ->
        super
        @action = opts.action
        @cancel = _.once => @trigger("cancel")
        @listenTo(asEvents(document), "click", @cancel)
        @listenTo(asEvents(document), "keyup", @cancel)
        @listenTo(asEvents(window), "blur", @cancel)

    context: -> {
        action: ACTIONS[@action]
        timer: 60
    }

    template: require "../templates/LogoutAction.hbs"


module.exports = LogoutAction


