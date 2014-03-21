Backbone = require "backbone"
ViewMaster = require "viewmaster"

LauncherModel = require "../models/LauncherModel.coffee"
MenuItemView = require "./MenuItemView.coffee"
LogoutButtonView = require "./LogoutButtonView.coffee"
Carousel = require "./Carousel.coffee"

class ProfileView extends ViewMaster

    className: "bb-profile"

    template: require "../templates/ProfileView.hbs"

    constructor: (opts) ->
        super
        @config = opts.config
        @user = opts.user

        if settingsCMD = @config.get("settingsCMD")
            @settings = new MenuItemView
                model: new LauncherModel settingsCMD
            @appendView ".settings-container", @settings

        if passwordCMD = @config.get("passwordCMD")
            @password = new MenuItemView
                model: new LauncherModel passwordCMD
            @appendView ".settings-container", @password

        if profileCMD = @config.get("profileCMD")
            @profile = new MenuItemView
                model: new LauncherModel profileCMD
            @appendView ".settings-container",  @profile

        if supportCMD = @config.get("supportCMD")
            @support = new MenuItemView
                model: new LauncherModel supportCMD
            @appendView ".settings-container",  @support

        @appendView ".settings-container", LogoutButtonView
        @appendView ".footer-container",  new Carousel
            collection: opts.feeds

    context: -> {
        user: @user.toJSON()
        config: @config.toJSON()
    }

module.exports = ProfileView
