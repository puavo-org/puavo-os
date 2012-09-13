
define [
  "backbone"
  "handlebars"
  "underscore"
], (Backbone, Handlebars, _) ->

  class View extends Backbone.View

    constructor: (opts) ->
      super
      @template = Handlebars.compile $(@templateQuery).html()

    viewJSON: -> {}

    render: ->
      @$el.html @template(@viewJSON())

