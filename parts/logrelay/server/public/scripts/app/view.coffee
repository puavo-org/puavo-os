
define [
  "backbone"
  "handlebars"
  "underscore"
], (Backbone, Handlebars, _) ->

  # Abstract view class
  class View extends Backbone.View

    constructor: (opts) ->
      super
      @template = Handlebars.compile $(@templateQuery).html()

    viewJSON: -> {}

    render: ->
      # console.info "rendering #{ @templateQuery } #{ @model?.id }"
      @$el.html @template(@viewJSON())

