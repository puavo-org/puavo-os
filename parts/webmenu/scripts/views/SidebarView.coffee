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
        @options = opts
        @user = opts.user

        @appendView ".profile-container", new ProfileView(@options)
        @carousel = new Carousel
            collection: @options.feeds

        @showDefaultItems()

        @listenTo this, "open-logout-view", =>
            console.log("open-logout-view")
            @showLogoutItems()

        @listenTo this, "open-root-view", =>
            console.log("open-root-view")
            @showDefaultItems()

    context: -> {
        user: @user.toJSON()
        config: @config.toJSON()
    }

    showLogoutItems: =>
        @carousel.detach()
        @$(".footer-container").empty()

        logoutItems = []

        if logoutCMD = @config.get("logoutCMD")
            logoutCMD["confirmText"] = "logout.logoutAction"
            logoutItems.push new MenuItemView
                model: new LauncherModel logoutCMD

        if not @config.get('webkioskMode')
            if not @config.get("guestSession")
                if lockCMD = @config.get("lockCMD")
                    logoutItems.unshift new MenuItemView
                        model: new LauncherModel lockCMD

            if restartCMD = @config.get("restartCMD")
                restartCMD["confirmText"] = "logout.restartAction"
                logoutItems.unshift new MenuItemView
                    model: new LauncherModel restartCMD

            if shutdownCMD = @config.get("shutdownCMD")
                shutdownCMD["confirmText"] = "logout.shutdownAction"
                logoutItems.unshift new MenuItemView
                    model: new LauncherModel shutdownCMD

            if @config.get("hostType") is "laptop"
                if sleepCMD = @config.get("sleepCMD")
                    logoutItems.push new MenuItemView
                        model: new LauncherModel sleepCMD

        @setView ".settings-container", logoutItems
        @refreshViews()

    showDefaultItems: =>
        defaultItems = []
        if settingsCMD = @config.get("settingsCMD")
            defaultItems.push new MenuItemView
                model: new LauncherModel settingsCMD

        if passwordCMD = @config.get("passwordCMD")
            defaultItems.push new MenuItemView
                model: new LauncherModel passwordCMD

        if supportCMD = @config.get("supportCMD")
            defaultItems.push new MenuItemView
                model: new LauncherModel supportCMD

        defaultItems.push LogoutButtonView

        @appendView ".footer-container", @carousel

        @setView ".settings-container", defaultItems
        @refreshViews()


module.exports = SidebarView
