
http = require "http"
{exec, spawn} = require "child_process"
app = require "appjs"
express = require "express"
stylus = require "stylus"

handler = express()

server = http.createServer(handler).listen 1337
bridge = require("./siobridge")(server)

handler.use stylus.middleware __dirname + "/content"
handler.use express.static __dirname + "/content"


window = app.createWindow
  width  : 1000
  height : 480
  top : 200
  showChrome: false
  disableSecurity: true
  icons  : __dirname + '/content/icons'
  url: "http://localhost:1337"


displayMenu = ->
  console.log "showing"
  title = "Opinsys Web Menu"
  window.frame.title = title
  window.frame.show()
  window.frame.focus()

  # gtk_window_present does not always give focus to us. Hack around with
  # wmctrl for now.
  # https://github.com/appjs/appjs/blob/f585f7ccfa7d2b54d910dd21d280ae4ad40f8f06/src/native_window/native_window_linux.cpp#L411
  setTimeout ->
    wmctrl = spawn("wmctrl", ["-a", title])
    wmctrl.on 'exit', (code) ->
      console.log('wmctrl exited with code ' + code)
  , 200

window.on 'create', ->
  console.log("Window Created")
  displayMenu()
  window.frame.center()
  # window.frame.openDevTools()


handler.get "/show", (req, res) ->
  res.send "ok"
  displayMenu()


bridge.on "open", (msg) ->
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

bridge.on "hideWindow", ->
  console.log "Hiding window"
  window.frame.hide()


