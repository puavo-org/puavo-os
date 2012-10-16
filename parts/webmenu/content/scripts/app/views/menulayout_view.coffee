define [
  "cs!app/views/layout"
  "cs!app/views/menulist_view"
  "cs!app/views/breadcrumbs_view"
  "cs!app/views/sidebar_view"
  "cs!app/views/favorites_view"
  "cs!app/application"
  "hbs!app/templates/menulayout"
  "backbone"
], (
  Layout
  MenuListView
  Breadcrumbs
  SidebarView
  Favorites
  Application
  template
  Backbone
) ->
  class MenuLayout extends Layout

    className: "bb-menu"

    template: template

    constructor: (opts) ->
      super
      @initialMenu = opts.initialMenu
      @allItems = opts.allItems

      @setMenu(@initialMenu)

      @bindTo Application, "show", =>
        @reset()
        @render()

      @bindTo @allItems, "select", (model) =>
        if model.get("type") is "menu"
          @setMenu model
          @renderSubviews()

      @_setView ".sidebar", new SidebarView

      @_setView ".favorites", new Favorites
        collection: @allItems

    reset: ->
      @setMenu(@initialMenu)

    setMenu: (model) ->
      @_setView ".menu-app-list-container", new MenuListView
        model: model
      @_setView ".breadcrums-container", new Breadcrumbs
        model: model


