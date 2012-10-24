
http = require "http"
{exec, spawn} = require "child_process"
app = require "appjs"
express = require "express"
stylus = require "stylus"
{argv} = require "optimist"
mkdirp = require "mkdirp"
menutools = require "./lib/menutools"
powermanager = require "./lib/powermanager"

handler = express()

server = http.createServer(handler).listen 1337
bridge = require("./lib/siobridge")(server)

handler.configure "development", ->
  handler.use stylus.middleware __dirname + "/content"
handler.use express.static __dirname + "/content"

cachePath = process.env.HOME + "/.webmenu/cache"
mkdirp.sync cachePath
app.init CachePath: cachePath

locale = process.env.LANG
locale = "fi_FI.UTF-8"
menuJSON = require "./menu.json"
menutools.injectDesktopData(menuJSON, "/usr/share/applications", locale)
handler.get "/menu.json", (req, res) ->
  console.log menuJSON
  res.json menuJSON


handler.get "/osicon/:icon.png", require("./routes/osicon")([
  "/usr/share/app-install/icons"
  "/usr/share/pixmaps"
  "/usr/share/icons/hicolor/128x128/apps"
])

window = app.createWindow
  width: 1000
  height: 550
  top: 200
  showChrome: false
  disableSecurity: true
  showOnTaskbar: false
  icons: __dirname + '/content/icons'
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


commandBuilders =
  desktop: (msg) ->
    if not msg.command
      console.error "Missing command from", msg
      return
    command = msg.command.shift()
    args = msg.command
    return [command, args]
  web: (msg) ->
    args = [msg.url]
    return ["xdg-open", args]

bridge.on "open", (msg) ->
  command = commandBuilders[msg.type]?(msg)

  if not command
    console.error "Cannot find command from", msg
    return

  [command, args] = command
  console.log "Executing '#{ command }'"
  cmd = spawn command, args, { detached: true }
  cmd.on "exit", (code) ->
    console.log "Command '#{ command } #{ args.join " " } exited with #{ code }"

bridge.on "openSettings", ->
  cmd = spawn "gnome-control-center", [], { detached: true }

bridge.on "hideWindow", ->
  console.log "Hiding window"
  window.frame.hide() if not argv["dev-tools"]

bridge.on "showMyProfileWindow", ->
  myProfileWindow = createMyProfileWindow()

  myProfileWindow.on 'create', ->
    displayMyProfileWindow(myProfileWindow)

bridge.on "shutdown", -> powermanager.shutdown()
bridge.on "reboot", -> powermanager.reboot()
bridge.on "logout", -> powermanager.logout()

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
  
