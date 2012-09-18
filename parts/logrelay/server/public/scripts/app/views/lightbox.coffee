define [
  "cs!app/view"
  "underscore"
], (View, _) ->

  class Lightbox extends View

    className: "bb-lightbox"
    templateQuery: "#lightbox"

    events:
      "click .background": -> @remove()

    constructor: (opts) ->
      super

    renderToBody: ->
      @render()
      $("body").append @el
