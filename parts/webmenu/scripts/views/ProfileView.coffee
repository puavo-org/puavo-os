ViewMaster = require "../vendor/backbone.viewmaster"

LauncherModel = require "../models/LauncherModel.coffee"
MenuItemView = require "./MenuItemView.coffee"
LogoutButtonView = require "./LogoutButtonView.coffee"

class ProfileView extends ViewMaster

  className: "bb-profile"

  template: require "../templates/ProfileView.hbs"

  constructor: (opts) ->
    super
    @config = opts.config

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

    @logout = new LogoutButtonView
      hostType: @config.get("hostType")
    @appendView ".settings-container", @logout

  context: -> {
    user: @model.toJSON()
    config: @config.toJSON()
  }

module.exports = ProfileView
