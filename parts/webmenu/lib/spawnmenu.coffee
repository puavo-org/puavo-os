###
Return event emitter which emits "spawn" events when the menu should be
presented to the user

TODO: Reimplement with dbus
###

net = require "net"
fs = require "fs"
{EventEmitter} = require "events"


module.exports = (pipePath) ->

  events = new EventEmitter

  try
    fs.unlinkSync(pipePath)
  catch err
    if err.code isnt "ENOENT"
      throw err

  server = net.createServer (socket) ->
    events.emit("spawn")
    socket.end("Spawning a menu for you!")

  server.listen(pipePath)

  return events
