define [
  "backbone.viewmaster"

  "cs!app/application"
  "cs!app/utils/navigation"
  "cs!app/views/menuitem_view"
  "hbs!app/templates/menulist"
], (
  ViewMaster

  Application
  Navigation
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

      @navigation = new Navigation @getMenuItemViews(), @itemCols()

      $(window).keydown (e) =>
        @navigation.cols = @itemCols()
        @navigation.handleKeyEvent(e)

      @listenTo this, "reset", =>
        @model = @initial
        @setCurrent()
        @refreshViews()
        @navigation.deactivate()

      @listenTo this, "open-menu", (model) =>
        @model = model
        @setCurrent()
        @refreshViews()

      @listenTo this, "search", (searchString) =>
        if searchString
          @setItems @collection.searchFilter(searchString)
        else
          @setCurrent()
        @refreshViews()
        @navigation.deactivate()

      @listenTo this, "scrollTo", (itemView) =>
        itemBottom = itemView.$el.offset().top + itemView.$el.innerHeight()
        itemTop = itemView.$el.offset().top

        menuListTop = @$el.offset().top
        menuListBottom = @$el.offset().top + @$el.innerHeight()

        if itemBottom > menuListBottom
          @$el.scrollTop( @$el.scrollTop() + itemBottom - menuListBottom )
        else if itemTop < menuListTop
          @$el.scrollTop( @$el.scrollTop() - (menuListTop - itemTop) )

    setCurrent: ->
      @setItems(@model.items.toArray())

    setItems: (models) ->
      @setView ".app-list-container", models.map (model) ->
        new MenuItemView
          model: model
      @$el.scrollTop(0)

    refreshViews: ->
      super
      @navigation.views = @getMenuItemViews()

    itemCols: ->
      parseInt(
        @$el.innerWidth() / @getMenuItemViews()[0].$el.innerWidth()
      )

    getMenuItemViews: ->
      @getViews(".app-list-container")
