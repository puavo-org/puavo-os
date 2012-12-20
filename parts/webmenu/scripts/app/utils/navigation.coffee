define [
], (
) ->
  class Navigation

    constructor: (views, cols) ->
      @views = views
      @cols = cols
      @selected = null

    select: (view) ->
      view.displaySelectHighlight()
      @selected = view

    next: ->
      @select(@views[0])

    down: ->
      @select(@views[0])
