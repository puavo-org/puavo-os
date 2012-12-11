define [
  "backbone.viewmaster"

  "cs!app/views/menuitem_view"

  "cs!app/application"
  "hbs!app/templates/menulist"
], (
  ViewMaster

  MenuItemView

  Application
  template
) ->

  class SearchResult extends ViewMaster

    className: "bb-menu"

    template: template

    constructor: (opts) ->
      super
      @allItems = opts.allItems


    displayItems: (filter) ->
      @setView ".menu-app-list", @allItems.searchFilter(filter).map (model) ->
        new MenuItemView
          model: model
