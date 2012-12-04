define [
  "backbone"
  "underscore"
  "socket.io"
], (
  Backbone
  _
  io
) ->

  class DesktopBridge extends Backbone.Model

    connect: (emitter) ->

      # Emit all application level events to Node.JS
      emitter.on "all", (event, args...) =>
        if args[0]?.node
          return

        console.info "Sending", event, args
        e = new window.Event event
        e.args = args
        window.dispatchEvent(e)

      ["show", "config"].forEach (nodejsEvent) =>
        window.addEventListener nodejsEvent, (e) =>
          console.log "FROM NODE", nodejsEvent, e
          @trigger nodejsEvent, e.args...
          console.info "triggered #{ nodejsEvent }"


