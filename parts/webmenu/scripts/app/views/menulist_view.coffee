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

    ENTER = 13
    TAB = 9

    className: "bb-menu-list"

    template: template

    constructor: (opts) ->
      super

      @initial = @model
      @setCurrent()

      @selected =
        index: 0
        item: null

      $(window).keydown (e) =>
        switch e.which
          when ENTER
            e.preventDefault()
            @selected.item?.open()
          when TAB
            e.preventDefault()
            if not @selected.item
              @selectItem(0)
            else
              @selectItem(@selected.index + 1)


      @listenTo this, "reset", =>
        @setItems(@initial.items.toArray())
        @deselectItem()
        @refreshViews()

      @listenTo this, "open:menu", (model) =>
        @model = model
        @setCurrent()
        @refreshViews()

      @listenTo this, "search", (searchString) =>
        if searchString
          @setItems @collection.searchFilter(searchString)
          @selectItem(0)
        else
          @setCurrent()
        @refreshViews()

    setCurrent: ->
      @setItems(@model.items.toArray())

    setItems: (models) ->
      @setView ".app-list-container", models.map (model) ->
        new MenuItemView
          model: model

    deselectItem: ->
      @selected.item?.hideSelectHighlight()
      @selected =
        index: 0
        item: null

    selectItem: (index) ->
      views = @getViews(".app-list-container")

      if views.length is 0
        @deselectItem()
        return

      @selected.item.hideSelectHighlight() if @selected.item
      @selected.index = index

      if not views[@selected.index]
        @selected.index = 0

      @selected.item = views[@selected.index]
      @selected.item.displaySelectHighlight()
