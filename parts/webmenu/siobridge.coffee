
# Cannot get Appjs to work with requirejs without disabling the
# Node.js<->Browser bridge. Use Socket.IO as the bridge for now.

{EventEmitter} = require "events"
sio = require "socket.io"

module.exports = (server) ->
  io = sio.listen(server)
  io.set "log level", 1
  listeners = []

  io.sockets.on "connection", (socket) ->
    listeners.forEach (args) ->
      socket.on args...

  return {
    on: (args...) -> listeners.push args
    emit: (args...) -> io.sockets.emit args...
  }
