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

    handleClient: (model) ->
      if model.get("hostname") is @id
        @clients.add model
      else
        @clients.remove model

    activeClientCount: ->
      count = 0
      @clients.each (m) ->
        if m.isConnected()
          count += 1
      return count

    connectedClients: (fn) ->
      @clients.filter (m) -> m.isConnected()

    seenClients: (fn) ->
      array = []
      @clients.each (m) ->
        if m.isConnected()
          array.push fn m
      return array



