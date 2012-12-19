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
    animationDuration: 2000
    reset: ->
      @bridge?.off()
      @bridge = new Backbone.Model

  Application.reset()

  return Application
