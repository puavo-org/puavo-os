define [
  "cs!app/views/layout"
  "cs!app/views/itemdescription_view"
  "cs!app/views/menulist_view"
  "cs!app/views/breadcrumbs_view"
  "cs!app/views/profile_view"
  "cs!app/views/favorites_view"
  "cs!app/application"
  "hbs!app/templates/menulayout"
  "app/utils/debounce"
  "backbone"
], (
  Layout
  ItemDescriptionView
  MenuListView
  Breadcrumbs
  ProfileView
  Favorites
  Application
  template
  debounce
  Backbone
) ->

  class MenuLayout extends Layout

    className: "bb-menu"

    template: template

    constructor: (opts) ->
      super
      @initialMenu = opts.initialMenu
      @allItems = opts.allItems
      @user = opts.user
      @config = opts.config

      @setMenu(@initialMenu)

      @bindTo Application, "show", =>
        @reset()
        @render()

      @bindTo @allItems, "select", (model) =>
        if model.get("type") is "menu"
          @setMenu model
          @renderSubviews(newOnly: true)

      delayedShowProfile = debounce =>
        @showProfile()
        @renderSubviews(newOnly: true)
      , 200

      @bindTo Application, "showDescription", (model) =>
        delayedShowProfile.cancel()
        @_setView ".sidebar", new ItemDescriptionView
          model: model
        @renderSubviews(newOnly: true)

      @bindTo Application, "hideDescription", => delayedShowProfile()

      @showProfile()

      @_setView ".favorites", new Favorites
        collection: @allItems
        config: @config

    showProfile: ->
      @_setView ".sidebar", new ProfileView
        model: @user
        config: @config

    reset: ->
      @setMenu(@initialMenu)

    setMenu: (model) ->
      @_setView ".menu-app-list-container", new MenuListView
        model: model
      @_setView ".breadcrums-container", new Breadcrumbs
        model: model


