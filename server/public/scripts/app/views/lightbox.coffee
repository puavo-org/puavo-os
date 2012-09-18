define [
  "cs!app/views/layout"
  "underscore"
], (Layout, _) ->

  class Lightbox extends Layout

    className: "bb-lightbox"
    templateQuery: "#lightbox"

    events:
      "click .background": -> @remove()
      "click .close": -> @remove()

    renderToBody: ->
      @render()
      $("body").append @el
