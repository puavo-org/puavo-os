define [
], (
) ->
  class Navigation

    @ENTER = 13
    @TAB = 9
    @LEFT = 37
    @UP = 38
    @RIGHT = 39
    @DOWN = 40

    constructor: (views, cols) ->
      @views = views
      @cols = cols
      @selected = null
      @currentIndex = 0

      $(window).keydown @handleKeyEvent

    handleKeyEvent: (e) =>
      key.ENTER


    isActive: -> !!@selected

    select: (view) ->
      view.displaySelectHighlight()
      @selected = view

    next: ->
      if @isActive()
        @currentIndex += 1

      @select(@views[@currentIndex])

    down: ->
      if not @isActive()
        @select(@views[@currentIndex])
        return

      if @isOnLastRow()
        @deactivate()
        return

      @currentIndex += @cols
      @select(@views[@currentIndex])

    deactivate: ->
      @selected?.hideSelectHighlight()
      @selected = null

    isOnFirstRow: -> @currentIndex+1 <= @cols
    isOnLastRow: -> @currentIndex > @views.length - @cols

    up: ->
      if @isOnFirstRow()
        @deactivate()
      else
        @currentIndex -= @cols
        @select(@views[@currentIndex])

    right: ->
      if (@currentIndex+1) % @cols is 0
        @currentIndex -= @cols-1
      else
        @currentIndex += 1
      @select(@views[@currentIndex])


    left: ->
      if @currentIndex % @cols is 0
        @currentIndex += @cols-1
      else
        @currentIndex -= 1
      @select(@views[@currentIndex])

