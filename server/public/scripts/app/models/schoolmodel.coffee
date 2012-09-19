define [
  "backbone"
  "underscore"
], (
  Backbone,
  _
) ->

  class SchoolModel extends Backbone.Model

    constructor: ->
      super

    logEvent: ->
      count = @get("eventCount") or 0
      @set "eventCount", count + 1
