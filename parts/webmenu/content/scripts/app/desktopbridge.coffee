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

    connect: (emitter) ->
      @io = io.connect()
      @io.on "connect", ->
        console.log "Socket.IO connected"

      # Emit all application level events to Node.JS
      emitter.on "all", (event, arg) =>
        @io.emit(event, arg)

      # Emit all Node.JS to application.
      #
      # Socket.IO does not have a catch all event. So we need to manually list
      # all events here.
      ["show"].forEach (nodejsEvent) =>
        @io.on nodejsEvent, => emitter.trigger nodejsEvent


