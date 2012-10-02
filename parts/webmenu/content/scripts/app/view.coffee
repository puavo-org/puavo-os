
define [
  "backbone"
  "underscore"
], (Backbone, Handlebars, _) ->

  # Abstract view class
  class View extends Backbone.View

    viewJSON: -> {}

    render: ->
      # console.info "rendering #{ @templateQuery } #{ @model?.id }"
      @$el.html @template(@viewJSON())

