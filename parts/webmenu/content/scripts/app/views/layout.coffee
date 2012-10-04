define [
  "cs!app/view"
  "underscore"
], (
  View
  _
) ->

  class Layout extends View

    constructor: (opts) ->
      super
      @subViews = opts?.subViews or {}

    eachSubView: (fn) ->
      for selector, views of @subViews
        container = @$(selector)
        fn(container, view) for view in views

    render: ->
      @eachSubView (container, view) ->
        view.$el.detach()
      super
      @eachSubView (container, view) ->
        view.render()
        container.append view.el

    setView: (selector, view) ->
      @subViews[selector] = [view]

    addView: (selector, view) ->
      a = @subViews[selector] ?= []
      a.push view


