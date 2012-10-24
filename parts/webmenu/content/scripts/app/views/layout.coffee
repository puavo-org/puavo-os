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
      @_remove = []


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
      opts ?= {}

      while oldView = @_remove.shift()
        oldView.remove()

      for selector, views of @subViews
        if opts.newOnly and not views._new
          continue

        container = @$(selector)
        container.children().detach() if not opts._noDetach

        for view in views
          view.render()
          container.append view.el
        views._new = false

    # Methods for setting views. Private because the selectors are always
    # internal to a layout. Add setMenu(view) method if you need public access.

    _setView: (selector, view) ->
      if _.isArray(view)
        newViews = view
      else
        newViews = [view]

      newViews._new = true

      if current = @subViews[selector]
        for old in _.difference(current, newViews)
          @_remove.push old

      @subViews[selector] = newViews


