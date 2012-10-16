define [
  "cs!app/views/layout"
  "hbs!app/templates/lightbox"
  "underscore"
  "backbone"
], (
  Layout
  template
  Backbone
  _
) ->

  class Lightbox extends Layout

    className: "bb-lightbox"

    template: template

    constructor: (opts) ->
      super
      @_setView ".content", opts.view

    events:
      "click .background": -> @remove()
      "click .close": -> @remove()

    remove: (opts)->
      super
      $("body").css "overflow", "auto"
      Lightbox.current = null

      if not opts?.silent
        @trigger "close"


    renderToBody: -> @render()

    render: ->
      # Only one Lightbox can be active at once
      Lightbox.current?.remove(silent: true)

      @$el.detach()
      super
      $("body").css "overflow", "hidden"
      $("body").append @el

      Lightbox.current = this

      # Restore event binding. Why needed?
      @delegateEvents()

