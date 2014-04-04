
ViewMaster = require "viewmaster"


class ProfileView extends ViewMaster

    className: "bb-profile"

    template: require "../templates/ProfileView.hbs"

    constructor: (opts) ->
        super
        @config = opts.config
        @user = opts.user

    context: -> {
        user: @user.toJSON()
        config: @config.toJSON()
    }

module.exports = ProfileView
