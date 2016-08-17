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


net = require "net"
fs = require "fs"
{EventEmitter} = require "events"

optimist = require "optimist"
_ = require "underscore"


createSpawnPipe = (socketPath, cb) ->

    events = new EventEmitter

    try
        fs.unlinkSync(socketPath)
    catch err
        if err.code isnt "ENOENT"
            throw err

    server = net.createServer (socket) ->
        buffer = ""

        emitSpawn = _.once ->
            socket.end()
            buffer = buffer.trim()
            if buffer
                options = optimist.parse(buffer.split(" "))
            else
                options = {}
            console.info "spawn: parsed #{ buffer } to #{ JSON.stringify options }"
            events.emit("spawn", options)

        socket.on "data", (data) ->
            buffer += data.toString()
            emitSpawn() if buffer.indexOf("\n") isnt -1

    console.log "Writing Webmenu spawn socket to #{ socketPath }"
    server.listen(socketPath, cb)

    return events

module.exports = createSpawnPipe
