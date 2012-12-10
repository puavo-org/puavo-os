define [
  "backbone"
  "underscore"

  "cs!app/utils/dom2bb"
], (
  Backbone
  _

  Dom2Bb
) ->
  Application =

    reset: ->
      @global = new Backbone.Model
      @bridge = new Backbone.Model

  Application.reset()

  return Application
