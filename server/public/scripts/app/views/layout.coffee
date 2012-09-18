define [
  "cs!app/view"
], (
  View
) ->
  class Layout extends View


    constructor: (opts) ->
      super
      @subViews = opts.subViews or {}

    eachSubView: (fn) ->
      for container, views of @subViews
        container = @$(container)
        if not _.isArray(views)
          fn container, views
        else
          fn(container, view) for view in views

    render: ->
      @eachSubView (container, view) ->
        view.$el.detach()
      super
      @eachSubView (container, view) ->
        view.render()
        container.append view.el
