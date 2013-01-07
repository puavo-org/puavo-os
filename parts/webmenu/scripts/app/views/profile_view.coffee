define [
  "backbone.viewmaster"

  "cs!app/models/launcher_model"
  "hbs!app/templates/profile"
  "hbs!app/templates/menuitem"
  "cs!app/views/menuitem_view"
  "cs!app/application"
  "cs!app/views/logout_view"
  "cs!app/views/lightbox_view"
], (
  ViewMaster

  LauncherModel
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

    constructor: (opts) ->
      super
      @listenTo this, "spawn-menu", @removeLightbox
      @lb = null
      @hostType = opts.hostType

    events:
      "click": ->
        @lb = new Lightbox
          view: new LogoutView
            hostType: @hostType
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
          model: new LauncherModel settingsCMD
        @appendView ".settings-container", @settings

      if passwordCMD = @config.get("passwordCMD")
        @password = new MenuItemView
          model: new LauncherModel passwordCMD
        @appendView ".settings-container", @password

      if profileCMD = @config.get("profileCMD")
        console.log "profile!", profileCMD
        @profile = new MenuItemView
          model: new LauncherModel profileCMD
        @appendView ".settings-container",  @profile

      @logout = new LogoutButton
        hostType: @config.get("hostType")
      @appendView ".settings-container", @logout

    context: -> {
      user: @model.toJSON()
      config: @config.toJSON()
    }
