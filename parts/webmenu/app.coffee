
http = require "http"
{exec, spawn} = require "child_process"
app = require "appjs"
express = require "express"
stylus = require "stylus"
{argv} = require "optimist"

handler = express()

server = http.createServer(handler).listen 1337
bridge = require("./siobridge")(server)

handler.use stylus.middleware __dirname + "/content"
handler.use express.static __dirname + "/content"

handler.get "/menu.json", (req, res) ->
  res.sendfile __dirname + "/menu.json"

window = app.createWindow
  width  : 1000
  height : 480
  top : 200
  showChrome: false
  disableSecurity: true
  icons  : __dirname + '/content/icons'
  disableBrowserRequire: true
  url: "http://localhost:1337"

displayMyProfileWindow = (myProfileWindow) ->
  title = "Opinsys - My Profile"
  myProfileWindow.frame.title = title
  myProfileWindow.frame.show()
  myProfileWindow.frame.focus()

displayMenu = ->
  console.log "showing"
  title = "Opinsys Web Menu"
  bridge.emit "show"
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
  if argv["dev-tools"]
    console.log "Opening devtools"
    window.frame.openDevTools()


handler.get "/show", (req, res) ->
  res.send "ok"
  displayMenu()


bridge.on "open", (msg) ->
  if msg.type is "desktop"
    command = msg.command.shift()
    args = msg.command
  else if msg.type is "web"
    command = "xdg-open"
    args = [msg.url]
  else
    return

  console.log "Executing '#{ command }'"
  cmd = spawn command, args, { detached: true }
  cmd.on "exit", (code) ->
    console.log "Command '#{ command } #{ args.join " " } exited with #{ code }"

bridge.on "hideWindow", ->
  console.log "Hiding window"
  window.frame.hide() if not argv["dev-tools"]

bridge.on "showMyProfileWindow", ->
  myProfileWindow = createMyProfileWindow()

  myProfileWindow.on 'create', ->
    displayMyProfileWindow(this)

createMyProfileWindow = () ->
  console.log "Create My Profile window"
  return app.createWindow
    width  : 800
    height : 530
    top : 200
    showChrome: true
    disableSecurity: true
    icons  : __dirname + '/content/icons'
    url: "http://puavo:3002/users/profile/edit?data-remote=true"
  
