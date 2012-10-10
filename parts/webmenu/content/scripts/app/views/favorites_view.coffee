define [
  "cs!app/views/layout"
  "cs!app/views/menuitem_view"
  "hbs!app/templates/favorites"
], (
  Layout
  MenuItemView
  template
) ->
  class Favorites extends Layout

    template: template

    constructor: ->
      super
      @bindTo @collection, "select", @render

    render: ->
      views = @collection.favorites(3).map (model) =>
        new MenuItemView model: model
      @_setView ".most-used-list", views

      super


