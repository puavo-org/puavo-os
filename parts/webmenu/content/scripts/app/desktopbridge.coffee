define [
  "backbone"
  "underscore"
  "socket.io"
], (
  Backbone
  _
  io
) ->

  class DesktopBridge

    constructor: ->
      _.extend this, Backbone.Events

    connect: ->
      @io = io.connect()
      @io.on "connect", ->
        console.log "Socket.IO connected"

      @io.on "show", => @trigger "show"

    hideWindow: -> @io.emit "hideWindow"
    open: (model) -> @io.emit "open", model.toJSON()

    showMyProfileWindow: -> @io.emit "showMyProfileWindow"

