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


    render: (opts) ->

      # Remove subviews with detach. This way they don't lose event handlers
      for selector, views of @subViews
        for view in views
          view.$el.detach()

      # Render layout from template like in normal view
      super

      opts = _.extend({}, opts)
      # No need to detach because they are already removed
      opts._noDetach = true
      @renderSubviews(opts)

    renderSubviews: (opts) ->
      for selector, views of @subViews when views.dirty
        container = @$(selector)
        container.children().detach() if not opts?._noDetach
        for view in views
          view.render()
          container.append view.el
        views.dirty = false

    # Methods for setting views. Private because the selectors are always
    # internal to a layout. Add setMenu(view) method if you need public access.

    _setView: (selector, view, render) ->
      views = @subViews[selector] = [view]
      views.dirty = true

    _addView: (selector, view) ->
      a = @subViews[selector] ?= []
      a.push view
      a.dirty = true

