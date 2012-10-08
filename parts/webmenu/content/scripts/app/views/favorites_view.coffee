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

      @collection.favorites(3).forEach (model) =>
        @_addView ".most-used-list", new MenuItemView
          model: model




