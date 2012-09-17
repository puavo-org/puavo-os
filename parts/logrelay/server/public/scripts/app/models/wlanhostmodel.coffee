define [
  "cs!app/models/wlanclientcollection"
  "backbone"
  "underscore"
], (
  WlanClientCollection,
  Backbone,
  _
) ->

  class WlanHostModel extends Backbone.Model

    constructor: (opts) ->
      if not opts.id
        opts.id = opts.hostname

      super

      @allClients = opts.allClients

      @clients = new WlanClientCollection

      @allClients.each (model) => @handleClient model
      @allClients.on "add change", (model, e) =>
        @handleClient model

    # Returns relative user count from 0-10
    # Used for animations
    relativeSize: ->
      count = @clients.activeClientCount()

      # No bars if no clients
      if count is 0
        return 0

      # One bar if there is one client
      if count is 1
        return 1

      # Otherwise just scale clients compared to all connected clients
      Math.round count / @allClients.activeClientCount() * 10, 1


    handleClient: (model) ->
      if model.get("hostname") is @id
        @clients.add model
      else
        @clients.remove model

    activeClientCount: -> @clients.activeClientCount()

    connectedClients: (fn) ->
      @clients.filter (m) -> m.isConnected()

    seenClients: (fn) ->
      array = []
      @clients.each (m) ->
        if m.isConnected()
          array.push fn m
      return array



