
ViewMaster = require "viewmaster"


class ProfileView extends ViewMaster

    className: "bb-profile"

    template: require "../templates/ProfileView.hbs"

    constructor: (opts) ->
        super
        @config = opts.config
        @user = opts.user
        @profileCMD = opts.config.get("profileCMD")

        @listenTo(@config, "change", @render)

    context: -> {
        user: @user.toJSON()
        config: @config.toJSON()
    }

    events: {
        "click .profile": (e) ->
            e.preventDefault()
            @bubble("open-app", {
                type: @profileCMD.type
                url: @profileCMD.url
            })
    }


module.exports = ProfileView
