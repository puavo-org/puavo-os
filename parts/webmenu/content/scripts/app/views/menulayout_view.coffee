define [
  "cs!app/views/layout"
  "cs!app/views/menulist_view"
  "cs!app/views/breadcrumbs_view"
  "hbs!app/templates/menulayout"
  "backbone"
], (
  Layout
  MenuListView
  Breadcrumbs
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

      @allItems.on "select", (model) =>
        console.log "Selecting", JSON.stringify(model.toJSON())
        if model.get("type") is "menu"
          @setMenu model
          @render()

    setMenu: (model) ->
      @_setView ".menu-app-list-container", new MenuListView
        model: model
      @_setView ".breadcrums-container", new Breadcrumbs
        model: model


