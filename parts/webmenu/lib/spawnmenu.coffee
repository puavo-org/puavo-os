###
Return event emitter which emits "spawn" events when the menu should be
presented to the user

TODO: Reimplement with dbus
###


# node-optimist crashes if process.env._ is undefined and it seems to undefined
# when launching Webmenu from a .desktop file. Eg. during login. Hack around by
# setting it to empty string. This hack should not affect us because we don't
# use implicit argv parsing from node-optimist.
if not process.env._
  process.env._ = ""

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
