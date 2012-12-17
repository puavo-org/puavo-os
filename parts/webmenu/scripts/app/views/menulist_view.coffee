define [
  "backbone.viewmaster"

  "cs!app/application"
  "cs!app/views/menuitem_view"
  "hbs!app/templates/menulist"
], (
  ViewMaster

  Application
  MenuItemView
  template
) ->
  class MenuListView extends ViewMaster

    className: "bb-menu"

    template: template

    constructor: (opts) ->
      super

      @initial = @model
      @setCurrent()

      @listenTo Application.global, "select", (model) =>
        if model.get("type") is "menu"
          @model = model
          @setCurrent()
          @refreshViews()

      if FEATURE_SEARCH
        @listenTo Application.global, "search", (filter) =>
          if filter.trim()
            @setItems @collection.searchFilter(filter)
          else
            @setCurrent()
          @refreshViews()

        @listenTo Application.global, "startFirstApplication",  =>
          if firtApp = @getViews(".menu-app-list")?[0].model
            Application.bridge.trigger "open", firtApp.toJSON()

    setRoot: ->
      @setItems(@initial.items.toArray())

    setCurrent: ->
      @setItems(@model.items.toArray())

    setItems: (models) ->
      @setView ".menu-app-list", models.map (model) ->
        new MenuItemView
          model: model

