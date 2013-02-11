###
Return event emitter which emits "spawn" events when the menu should be
presented to the user

TODO: Reimplement with dbus
###

optimist = require "optimist"

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
    socket.end("Spawning a menu for you!")
    buffer = ""
    socket.on "data", (data) ->
      buffer += data.toString()

    socket.on "close", ->
      if buffer.trim()
        options = optimist.parse(buffer.split(" "))
      else
        options = {}
      events.emit("spawn", options)

  server.listen(pipePath)

  return events
