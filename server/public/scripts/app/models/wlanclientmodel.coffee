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
        if @isConnected()
          @history.push
            hostname: model.changed.hostname
            timestamp: model.changed.relay_timestamp


    isConnected: ->
      @get("event") is @connectEvent
