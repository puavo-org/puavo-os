
define [
  "backbone"
  "underscore"
], (Backbone, Handlebars, _) ->

  # Abstract view class
  class View extends Backbone.View

    viewJSON: ->
      return @model.toJSON() if @model
      return {}

    render: ->
      @$el.html @template(@viewJSON())

