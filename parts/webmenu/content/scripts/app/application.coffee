define [
  "backbone"
  "underscore"

  "cs!app/bridge"
], (
  Backbone
  _

  Bridge
) ->
  Application =

    reset: ->
      @global = new Backbone.Model
      @bridge = new Bridge "browser->node", window

  Application.reset()

  return Application
