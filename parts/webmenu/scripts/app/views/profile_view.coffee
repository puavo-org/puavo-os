define [
  "backbone.viewmaster"

  "cs!app/models/launcher_model"
  "hbs!app/templates/profile"
  "cs!app/views/menuitem_view"
  "cs!app/views/logout_button_view"
  "cs!app/application"
], (
  ViewMaster

  LauncherModel
  template
  MenuItemView
  LogoutButtonView
  Application
) ->

  class ProfileView extends ViewMaster

    className: "bb-profile"

    template: template


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
