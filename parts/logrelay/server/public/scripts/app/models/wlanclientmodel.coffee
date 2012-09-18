define [
  "backbone"
  "underscore"
], (Backbone, _) ->

  class WlanClientModel extends Backbone.Model

    connectEvent: "AP-STA-CONNECTED"

    constructor: (opts) ->
      opts.id = opts.mac
      super
      @history = []

      @on "change add", (model) =>
        @history.push
          event: model.get("event")
          hostname: model.get("hostname")
          timestamp: model.get("relay_timestamp")


    isConnected: ->
      @get("event") is @connectEvent
