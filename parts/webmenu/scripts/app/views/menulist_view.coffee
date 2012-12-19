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
    ARROWKEYS = {
      40: 'down',
      38: 'up',
      39: 'right',
      37: 'left'
    }

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

        if Object.keys(ARROWKEYS).indexOf( e.which.toString() ) isnt -1
          e.preventDefault()
          @moveSelectItem(ARROWKEYS[e.which])


      @listenTo this, "reset", =>
        @setItems(@initial.items.toArray())
        @deselectItem()
        @refreshViews()

      @listenTo this, "open:menu", (model) =>
        @animate "bounceOutLeft", =>
          @model = model
          @setCurrent()
          @deselectItem()
          @refreshViews()
          @animate "bounceInRight"


      @listenTo this, "search", (searchString) =>
        if searchString
          @setItems @collection.searchFilter(searchString)
          @selectItem(0)
        else
          @setCurrent()
          @deselectItem()
        @refreshViews()

    # className from http://daneden.me/animate/
    animate: (className, cb) ->
      className = "animated " + className
      @$el.addClass(className)
      setTimeout =>
        @$el.removeClass(className)
        cb?()
      , 310

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

      @selected.cols = parseInt( @$el.innerWidth() / views[0].$el.innerWidth() )

      @selected.item.hideSelectHighlight() if @selected.item
      @selected.index = index

      if not views[@selected.index]
        @selected.index = 0

      @selected.item = views[@selected.index]
      @selected.item.displaySelectHighlight()

    moveSelectItem: (key) ->
      if not @selected.item
        @selectItem(0)
        return
  
      switch key
        when "down"
          @selectItem( @selected.index + @selected.cols )
        when "up"
          @selectItem( @selected.index - @selected.cols )
        when "right"
          @selectItem(@selected.index + 1)
        when "left"
          if @selected.index is 0
            @selectItem(@getViews(".app-list-container").length - 1)
          else
            @selectItem(@selected.index - 1)
