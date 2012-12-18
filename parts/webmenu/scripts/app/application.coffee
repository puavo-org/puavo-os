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
      @bridge?.off()
      @bridge = new Backbone.Model

  Application.reset()

  return Application
