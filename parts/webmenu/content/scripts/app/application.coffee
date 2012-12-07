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
      @bridge = new Dom2Bb window

  Application.reset()

  return Application
