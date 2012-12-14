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

    setItems: (models) ->
      @setView ".menu-app-list", models.map (model) ->
        new MenuItemView
          model: model
      @refreshViews()
