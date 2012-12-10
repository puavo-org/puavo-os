define [
  "backbone.viewmaster"

  "cs!app/views/menuitem_view"
  "hbs!app/templates/favorites"
], (
  ViewMaster

  MenuItemView
  template
) ->
  class Favorites extends ViewMaster

    template: template

    constructor: (opts) ->
      super
      @config = opts.config
      @bindTo @collection, "select", @render

    render: ->
      views = @collection.favorites(@config.get "maxFavorites").map (model) =>
        new MenuItemView model: model
      @setView ".most-used-list", views

      super


