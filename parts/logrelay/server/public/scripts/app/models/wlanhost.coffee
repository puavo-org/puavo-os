define [
  "backbone"
  "underscore"
], (Backbone, _) ->

  class WlanClient extends Backbone.Model

    isConnected: -> true


  class WlanHost extends Backbone.Model

    constructor: ->
      super
      @clients = new Backbone.Collection

    activeClientCount: ->
      count = 0
      @clients.each (m) ->
        if m.isConnected()
          count += 1
      return count

    mapActiveClients: (fn) ->
      array = []
      @clients.each (m) ->
        if m.isConnected()
          array.push fn m
      return array


    addPacket: (packet) ->
      client = @clients.get packet.mac

      if not client
        client = new WlanClient id: packet.mac
        @clients.add client

      client.set packet

      client

