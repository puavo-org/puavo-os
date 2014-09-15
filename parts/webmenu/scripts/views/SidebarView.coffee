Backbone = require "backbone"
ViewMaster = require "viewmaster"

LauncherModel = require "../models/LauncherModel.coffee"
MenuItemView = require "./MenuItemView.coffee"
LogoutButtonView = require "./LogoutButtonView.coffee"
LockScreenButtonView = require "./LockScreenButtonView.coffee"
Carousel = require "./Carousel.coffee"
ProfileView = require "./ProfileView.coffee"

class SidebarView extends ViewMaster

    className: "bb-sidebar"

    template: require "../templates/SidebarView.hbs"

    constructor: (opts) ->
        super
        @config = opts.config
        @user = opts.user

        @appendView ".profile-container", new ProfileView(opts)

        @defaultItems = []
        if settingsCMD = @config.get("settingsCMD")
            @defaultItems.push new MenuItemView
                model: new LauncherModel settingsCMD

        if passwordCMD = @config.get("passwordCMD")
            @defaultItems.push new MenuItemView
                model: new LauncherModel passwordCMD

        if supportCMD = @config.get("supportCMD")
            @defaultItems.push new MenuItemView
                model: new LauncherModel supportCMD

        @defaultItems.push LogoutButtonView

        @logoutItems = []
        if shutdownCMD = @config.get("shutdownCMD")
            shutdownCMD["confirmText"] = "logout.shutdownAction"
            @logoutItems.push new MenuItemView
                model: new LauncherModel shutdownCMD
        if restartCMD = @config.get("restartCMD")
            restartCMD["confirmText"] = "logout.restartAction"
            @logoutItems.push new MenuItemView
                model: new LauncherModel restartCMD

        if lockCMD = @config.get("lockCMD")
            @logoutItems.push new MenuItemView
                model: new LauncherModel lockCMD

        if logoutCMD = @config.get("logoutCMD")
            logoutCMD["confirmText"] = "logout.logoutAction"
            @logoutItems.push new MenuItemView
                model: new LauncherModel logoutCMD

        if sleepCMD = @config.get("sleepCMD")
            @logoutItems.push new MenuItemView
                model: new LauncherModel sleepCMD

        @carousel = new Carousel
            collection: opts.feeds

        @showDefaultItems()

        @listenTo this, "open-logout-view", =>
            @showLogoutItems()

        @listenTo this, "open-root-view", =>
            @showDefaultItems()

    context: -> {
        user: @user.toJSON()
        config: @config.toJSON()
    }

    showLogoutItems: =>
        @$(".footer-container").empty()
        @setView ".settings-container", @logoutItems
        @refreshViews()

    showDefaultItems: =>
        @appendView ".footer-container", @carousel
        @setView ".settings-container", @defaultItems
        @refreshViews()


module.exports = SidebarView
