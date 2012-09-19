define [
  "cs!app/views/layout"
  "underscore"
], (Layout, _) ->

  class Lightbox extends Layout

    constructor: ->
      super
      @_visible = false

    events:
      "click .background": -> @remove()
      "click .close": -> @remove()

    remove: ->
      super
      $("body").css "overflow", "auto"

    detach: ->
      @$el.detach()
      @_visible = false

    isVisible: -> @_visible

    renderToBody: ->
      @detach()
      @render()
      $("body").css "overflow", "hidden"
      $("body").append @el
      @_visible = true
      # Restore event binding. Why needed?
      @delegateEvents()
