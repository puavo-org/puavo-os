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

      @listenTo this, "open:menu", (model) =>
        @model = model
        @setCurrent()
        @refreshViews()

      @listenTo this, "search", (searchString) =>
        if searchString.trim()
          @setItems @collection.searchFilter(searchString)
          @setStartApplication(0)
        else
          @setCurrent()
        @refreshViews()

      @listenTo this, "startApplication",  =>
        if @startApp?.model
          @bubble "open:app", @startApp.model
          @startApp = null

      @listenTo this, "nextStartApplication", =>
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
      views = @getViews(".app-list-container")

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
