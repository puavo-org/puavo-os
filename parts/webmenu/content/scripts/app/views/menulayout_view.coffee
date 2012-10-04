define [
  "cs!app/views/layout"
  "cs!app/views/menulist_view"
  "hbs!app/templates/menulayout"
  "backbone"
], (
  Layout
  MenuListView
  template
  Backbone
) ->
  class MenuLayout extends Layout

    className: "bb-menu"

    template: template

    constructor: (opts) ->
      super
      @setMenu(@model)

      opts.allItems.on "select", (model) =>
        console.log "Selecting", JSON.stringify(model.toJSON())

        if model.get("type") is "menu"
          @setMenu model
          @render()


    setMenu: (model) ->
      @_setView ".menu-app-list-container", new MenuListView
        model: model


