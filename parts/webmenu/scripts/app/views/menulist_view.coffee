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

    className: "bb-menu-list"

    template: template

    constructor: (opts) ->
      super

      @initial = @model
      @setCurrent()
      @startApp = null
      @startAppIndex = 0

      @listenTo Application.global, "select", (model) =>
        if model.get("type") is "menu"
          @model = model
          @setCurrent()
          @refreshViews()

      if FEATURE_SEARCH
        @listenTo Application.global, "search", (filter) =>
          if filter.trim()
            @setItems @collection.searchFilter(filter)
            @setStartApplication(0)
          else
            @setCurrent()
          @refreshViews()

        @listenTo Application.global, "startApplication",  =>
          if @startApp?.model
            Application.global.trigger "select", @startApp.model
            @startApp = null

        @listenTo Application.global, "nextStartApplication", =>
          @setStartApplication(@startAppIndex + 1)

    setRoot: ->
      @setItems(@initial.items.toArray())

    setCurrent: ->
      @setItems(@model.items.toArray())

    setItems: (models) ->
      @setView ".app-list-container", models.map (model) ->
        new MenuItemView
          model: model

    setStartApplication: (index) ->
      views = @getViews(".menu-app-list")

      if views.length is 0
        @startApp = null
        @startAppIndex = 0
        return
  
      @startApp.hideSelectHighlight() if @startApp
      @startAppIndex = index

      if not views[@startAppIndex]
        @startAppIndex = 0
  
      @startApp = views[@startAppIndex]
      @startApp.displaySelectHighlight()
