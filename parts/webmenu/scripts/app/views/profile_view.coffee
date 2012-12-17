define [
  "backbone.viewmaster"

  "cs!app/models/menu_model"
  "hbs!app/templates/profile"
  "cs!app/views/menuitem_view"
  "cs!app/application"
  "cs!app/views/logout_view"
  "cs!app/views/lightbox_view"
], (
  ViewMaster

  MenuModel
  template
  MenuItemView
  Application
  LogoutView
  Lightbox
) ->

  class ProfileView extends ViewMaster

    className: "bb-profile"

    template: template

    #     @lb = new Lightbox
    #       view: new LogoutView
    #     @lb.render()

    constructor: (opts) ->
      super
      @config = opts.config
      @listenTo Application.global, "show", =>
        @lb?.remove()

      @appendView ".settings-container", new MenuItemView
        model: new MenuModel.LauncherModel @config.get("settingsCMD")

      if passwordCMD = @config.get("passwordCMD")
        @appendView ".settings-container", new MenuItemView
          model: new MenuModel.LauncherModel passwordCMD

      if profileCMD = @config.get("profileCMD")
        @appendView ".settings-container", new MenuItemView
          model: new MenuModel.LauncherModel profileCMD


    context: -> {
      user: @model.toJSON()
      config: @config.toJSON()
    }

    remove: ->
      @lb?.remove()
      super
