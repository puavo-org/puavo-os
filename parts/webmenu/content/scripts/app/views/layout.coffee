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
      # Remove subviews with detach. This way they don't lose event handlers
      @eachSubView (container, view) -> view.$el.detach()

      # Render layout from template like in normal view
      super

      # Render subviews and put them back to their containers
      @eachSubView (container, view) ->
        view.render()
        container.append view.el

    # Methods for setting views. Private because the selectors are internal to
    # a layout always. Add setMenu(view) method if you need public access.

    _setView: (selector, view) ->
      @subViews[selector] = [view]

    _addView: (selector, view) ->
      a = @subViews[selector] ?= []
      a.push view


