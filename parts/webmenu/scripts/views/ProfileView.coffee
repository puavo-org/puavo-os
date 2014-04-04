
ViewMaster = require "viewmaster"


class ProfileView extends ViewMaster

    className: "bb-profile"

    template: require "../templates/ProfileView.hbs"

    constructor: (opts) ->
        super
        @config = opts.config
        @user = opts.user
        @profileCMD = opts.config.get("profileCMD")

    context: -> {
        user: @user.toJSON()
        config: @config.toJSON()
    }

    events: {
        "click a": (e) ->
            e.preventDefault()
            @bubble("open-app", {
                type: @profileCMD.type
                url: @profileCMD.url
            })
    }


module.exports = ProfileView
