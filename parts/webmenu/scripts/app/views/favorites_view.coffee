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

    className: "bb-favorites"

    template: template

    constructor: (opts) ->
      super
      @config = opts.config

      @setList()
      @listenTo @collection, "change:clicks", =>
        @setList()
        @refreshViews()

    setList: ->
      views = @collection.favorites(@config.get "maxFavorites").map (model) =>
        new MenuItemView model: model
      @setView ".app-list-container", views



