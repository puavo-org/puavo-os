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

    displayItems: (filter) ->
      @setView ".menu-app-list", @collection.searchFilter(filter).map (model) ->
        new MenuItemView
          model: model
