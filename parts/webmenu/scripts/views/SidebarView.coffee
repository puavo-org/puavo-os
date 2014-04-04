Backbone = require "backbone"
ViewMaster = require "viewmaster"

LauncherModel = require "../models/LauncherModel.coffee"
MenuItemView = require "./MenuItemView.coffee"
LogoutButtonView = require "./LogoutButtonView.coffee"
Carousel = require "./Carousel.coffee"
ProfileView = require "./ProfileView.coffee"

class SidebarView extends ViewMaster

    className: "bb-sidebar"

    template: require "../templates/SidebarView.hbs"

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

        if supportCMD = @config.get("supportCMD")
            @support = new MenuItemView
                model: new LauncherModel supportCMD
            @appendView ".settings-container",  @support

        @appendView ".profile-container", new ProfileView(opts)
        @appendView ".settings-container", LogoutButtonView
        @appendView ".footer-container",  new Carousel
            collection: opts.feeds

    context: -> {
        user: @user.toJSON()
        config: @config.toJSON()
    }

module.exports = SidebarView
