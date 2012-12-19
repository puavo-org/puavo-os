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
      @listenTo this, "spawn-menu", @removeLightbox
      @lb = null

    events:
      "click": ->
        @lb = new Lightbox
          view: new LogoutView
        @lb.render()
        @lb.listenTo @lb, "all", (event) =>
          @bubble event

    removeLightbox: ->
      @lb?.remove()
      @lb = null

    remove: ->
      @removeLightbox()
      super

    context: ->
      cssIcon: "icon-logout"
      name: "Kirjaudu ulos"

  class ProfileView extends ViewMaster

    className: "bb-profile"

    template: template


    constructor: (opts) ->
      super
      @config = opts.config

      if settingsCMD = @config.get("settingsCMD")
        @settings = new MenuItemView
          model: new MenuModel.LauncherModel settingsCMD
        @appendView ".settings-container", @settings

      if passwordCMD = @config.get("passwordCMD")
        @password = new MenuItemView
          model: new MenuModel.LauncherModel passwordCMD
        @appendView ".settings-container", @password

      if profileCMD = @config.get("profileCMD")
        console.log "profile!", profileCMD
        @profile = new MenuItemView
          model: new MenuModel.LauncherModel profileCMD
        @appendView ".settings-container",  @profile

      @logout = new LogoutButton
      @appendView ".settings-container", @logout

    context: -> {
      user: @model.toJSON()
      config: @config.toJSON()
    }
