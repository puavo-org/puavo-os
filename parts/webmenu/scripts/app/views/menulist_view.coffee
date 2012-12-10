define [
  "backbone.viewmaster"

  "cs!app/views/menuitem_view"
  "hbs!app/templates/menulist"
], (
  ViewMaster

  MenuItemView
  template
) ->
  class MenuListView extends ViewMaster

    className: "bb-menu"

    template: template

    constructor: ->
      super

      if @model.get("type") isnt "menu"
        throw new Error "Bad menu list model type: #{ @model.get("type") }"

      @setView ".menu-app-list", @model.items.map (model) ->
        new MenuItemView
          model: model

