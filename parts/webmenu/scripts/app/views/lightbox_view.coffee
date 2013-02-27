define [
  "backbone.viewmaster"

  "hbs!app/templates/lightbox"
  "underscore"
  "backbone"
], (
  ViewMaster

  template
  Backbone
  _
) ->

  class Lightbox extends ViewMaster

    className: "bb-lightbox"

    template: template

    constructor: (opts) ->
      super
      @setView ".content", opts.view
      if opts.position
        @$el.addClass(opts.position)
      @listenTo this, "cancel", @remove

      $(document).on "click", @bgClick = (e) =>
        if e.target is @$background[0]
          @remove()

    elements:
      "$background": ".background"

    remove: (opts) ->
      super
      $(document).off("click", @bgClick)
      if not opts?.silent
        @trigger "close"

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

