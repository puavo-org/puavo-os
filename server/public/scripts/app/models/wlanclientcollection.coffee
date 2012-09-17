
define [
  "cs!app/models/wlanclientmodel"
  "backbone"
  "underscore"
], (WlanClientModel, Backbone, _) ->

  class WlanClientCollection extends Backbone.Collection

    model: WlanClientModel

    # Client collection from a log packet
    update: (packet) ->
      client = @get packet.mac

      # Just update existing client
      if client
        client.set packet
      else
        # Add packet as new client
        client = new @model packet
        @add client


    activeClientCount: ->
      connectedCount = @reduce (memo, m) ->
        if m.isConnected() then memo+1 else memo
      , 0
