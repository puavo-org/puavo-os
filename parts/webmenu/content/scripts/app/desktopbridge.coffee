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

    connect: ->
      @io = io.connect()
      @io.on "connect", ->
        console.log "Socket.IO connected"

    hideWindow: -> @io.emit "hideWindow"

