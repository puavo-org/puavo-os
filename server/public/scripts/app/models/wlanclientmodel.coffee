define [
  "backbone"
  "underscore"
], (Backbone, _) ->

  class WlanClientModel extends Backbone.Model

    constructor: (opts) ->
      opts.id = opts.mac
      super

    isConnected: ->
      @get("event") is "AP-STA-CONNECTED"
