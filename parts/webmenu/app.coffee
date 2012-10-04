
http = require "http"
{exec} = require "child_process"
app = require "appjs"
express = require "express"
stylus = require "stylus"

handler = express()

server = http.createServer(handler).listen 1234

handler.use stylus.middleware __dirname + "/content"
handler.use express.static __dirname + "/content"

io = require("socket.io").listen(server)
io.set "log level", 1
io.sockets.on "connection", (socket) ->
  console.info "socket connection"

  socket.on "hideWindow", (msg) ->
    console.info "gotta hide this window"

  socket.on "open", (msg) ->
    if msg.type is "desktop"
      command = msg.command
    else if msg.type is "web"
      command = "xdg-open #{ msg.url }"
    else
      return

    console.log "Executing '#{ command }'"
    exec command, (err) ->
      if err
        console.error "Failed to execute", command, err



# app.serveFilesFrom(__dirname + '/content');


window = app.createWindow
  width  : 1000
  height : 480
  top : 200
  showChrome: false
  disableSecurity: true
  icons  : __dirname + '/content/icons'
  url: "http://localhost:1234"

window.on 'create', ->
  console.log("Window Created")
  window.frame.show()
  window.frame.center()
  # window.frame.openDevTools()

