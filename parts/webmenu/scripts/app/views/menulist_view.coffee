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
    LEFT = 37
    UP = 38
    RIGHT = 39
    DOWN = 40

    className: "bb-menu-list"

    template: template

    constructor: (opts) ->
      super

      @initial = @model
      @setCurrent()

      @selected =
        index: 0
        item: null
        cols: 0
        enabled: false

      $(window).keydown (e) =>
        switch e.which
          when ENTER
            e.preventDefault()
            if @selected.item
              @selected.item?.open()
            else
              @getViews(".app-list-container")[0].open()
          when TAB
            e.preventDefault()
            if not @selected.enabled
              @enableSelected()
            else
              @selectItem(@selected.index + 1)

        if [LEFT,UP,RIGHT].indexOf( e.which ) isnt -1
          if @selected.enabled
            e.preventDefault() 
            @moveSelectItem(e.which)

        if e.which is DOWN
          e.preventDefault() 
          if not @selected.enabled
            @enableSelected()
          else
            @moveSelectItem(e.which)


      @listenTo this, "reset", =>
        @setItems(@initial.items.toArray())
        @deselectItem()
        @refreshViews()

      @listenTo this, "open-menu", (model) =>
        @model = model
        @setCurrent()
        @deselectItem()
        @refreshViews()


      @listenTo this, "search", (searchString) =>
        if searchString
          @setItems @collection.searchFilter(searchString)
        else
          @setCurrent()
          @deselectItem()
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
        cols: 0
        enabled: false

    selectItem: (index) ->
      views = @getViews(".app-list-container")

      if views.length is 0
        @deselectItem()
        return

      @selected.cols = parseInt( @$el.innerWidth() / views[0].$el.innerWidth() )

      @selected.item.hideSelectHighlight() if @selected.item
      @selected.index = index

      if not views[@selected.index]
        @selected.index = 0

      @selected.item = views[@selected.index]
      @selected.item.displaySelectHighlight()

    moveSelectItem: (key) ->
      views = @getViews(".app-list-container")

      if not @selected.item
        @selectItem(0)
        return
  
      switch key
        when DOWN
          @selectItem( @selected.index + @selected.cols )
        when UP
          if not views[@selected.index - @selected.cols]
            @deselectItem()
            return
          @selectItem( @selected.index - @selected.cols )
        when RIGHT
          @selectItem(@selected.index + 1)
        when LEFT
          if @selected.index is 0
            @selectItem(views.length - 1)
          else
            @selectItem(@selected.index - 1)

    enableSelected: ->
      @selected.enabled = true
      @selectItem(0)