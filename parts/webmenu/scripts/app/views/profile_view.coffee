define [
  "backbone.viewmaster"

  "cs!app/models/menu_model"
  "hbs!app/templates/profile"
  "hbs!app/templates/menuitem"
  "cs!app/views/menuitem_view"
  "cs!app/application"
  "cs!app/views/logout_view"
  "cs!app/views/lightbox_view"
], (
  ViewMaster

  MenuModel
  template
  menuItemTemplate
  MenuItemView
  Application
  LogoutView
  Lightbox
) ->

  class LogoutButton extends ViewMaster

    className: "bb-menu-item"

    template: menuItemTemplate

    constructor: ->
      super
      @listenTo this, "spawnMenu", @removeLightbox

    events:
      "click": ->
        @lb = new Lightbox
          view: new LogoutView
        @lb.render()

    removeLightbox: ->
      @lb?.remove()

    context: ->
      cssIcon: "icon-logout"
      name: "Kirjaudu ulos"

  class ProfileView extends ViewMaster

    className: "bb-profile"

    template: template


    constructor: (opts) ->
      super
      @config = opts.config
      @listenTo this, "spawnMenu", =>
        @lb?.remove()

      @appendView ".settings-container", new MenuItemView
        model: new MenuModel.LauncherModel @config.get("settingsCMD")

      if passwordCMD = @config.get("passwordCMD")
        @appendView ".settings-container", new MenuItemView
          model: new MenuModel.LauncherModel passwordCMD

      if profileCMD = @config.get("profileCMD")
        @appendView ".settings-container", new MenuItemView
          model: new MenuModel.LauncherModel profileCMD

      @appendView ".settings-container", new LogoutButton


    context: -> {
      user: @model.toJSON()
      config: @config.toJSON()
    }

    remove: ->
      @lb?.remove()
      super
