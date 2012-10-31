
http = require "http"
{spawn} = require "child_process"

app = require "appjs"
express = require "express"
stylus = require "stylus"
nib = require "nib"
posix = require "posix"
mkdirp = require "mkdirp"
rimraf = require "rimraf"
optimist = require("optimist")
  .usage("Usage: webmenu [options]")
  .alias("h", "help")
  .alias("v", "verbose")
  .describe("dev-tools", "Open Webkit inspector")
  .describe("reset-favorites", "Reset favorites list")
argv = optimist.argv


clim = require "clim"
clim(console, true)
_logWrite = clim.logWrite
clim.logWrite = (level, prefixes, msg) ->
  if level is "LOG" and not argv.verbose
    return
  _logWrite(level, prefixes, msg)



launchCommand = require "./lib/launchcommand"
menutools = require "./lib/menutools"
powermanager = require "./lib/powermanager"
requirefallback = require "./lib/requirefallback"

webmenuHome = process.env.HOME + "/.config/webmenu"
cachePath = webmenuHome + "/cache"
spawnPipePath = webmenuHome + "/spawnpipe"

spawnEmitter = require("./lib/spawnevents")(spawnPipePath)

if argv.help
  optimist.showHelp (msg) ->
    process.stderr.write(msg + "\n")
  process.exit(0)

if argv["reset-favorites"]
  rimraf.sync(cachePath)
  process.exit(0)

config = requirefallback(
  webmenuHome + "/config.json"
  "/etc/webmenu/config.json"
  __dirname + "/config.json"
)

handler = express()

config.port ?= 1337
server = http.createServer(handler).listen config.port or 1337, ->
  console.warn "HTTP server listening on port #{ config.port }."
  console.warn "Yes, this sucks and it will be fixed on a later release. https://github.com/opinsys/webmenu/issues/2"
bridge = require("./lib/siobridge")(server)

handler.configure "development", ->

  compile = (str, path) ->
    stylus(str)
      .set("paths", [
        __dirname + "/content/styles"
      ])
      .use(nib())

  handler.use stylus.middleware
    compile: compile
    src: __dirname + "/content"

handler.use express.static __dirname + "/content"

mkdirp.sync(cachePath)
app.init(CachePath: cachePath)


locale = process.env.LANG
locale = "fi_FI.UTF-8"
menuJSON = requirefallback(
  webmenuHome + "/menu.json"
  "/etc/webmenu/menu.json"
  __dirname + "/menu.json"
)

menutools.injectDesktopData(
  menuJSON
  config.dotDesktopSearchPaths
  locale
)

username = posix.getpwnam(posix.geteuid()).name
userData = posix.getpwnam(username)
userData.fullName = userData.gecos.split(",")[0]

handler.get "/user.json", (req, res) -> res.json(userData)
handler.get "/menu.json", (req, res) -> res.json(menuJSON)
handler.get "/config.json", (req, res) -> res.json(config)

handler.get "/osicon/:icon.png", require("./routes/osicon")(
  config.iconSearchPaths
  config.fallbackIcon
)

window = app.createWindow
  width: 1000
  height: 550
  top: 200
  showChrome: false
  disableSecurity: true
  showOnTaskbar: false
  icons: __dirname + '/content/icons'
  disableBrowserRequire: true
  url: "http://localhost:#{ config.port }"

displayMenu = ->
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
      if code isnt 0
        console.info('wmctrl exited with code ' + code)
  , 200


window.on "create", ->
  displayMenu()
  window.frame.center()
  if argv["dev-tools"]
    console.info "Opening devtools"
    window.frame.openDevTools()

window.on "ready", ->
  window.addEventListener "keydown", (e) ->
    if e.keyIdentifier is "F12"
      argv["dev-tools"] = true
      window.frame.openDevTools()


# TODO: legacy. remove
handler.get "/show", (req, res) ->
  res.send "ok"
  console.warn "Called legacy http /show Use nc -w 1 -U #{ spawnPipePath }"
  displayMenu()

spawnEmitter.on "spawn", displayMenu

bridge.on "open", (msg) ->
  launchCommand(msg)
  window.frame.hide()

bridge.on "openSettings", ->
  launchCommand(config.settingsCMD)
  window.frame.hide()

bridge.on "hideWindow", ->
  window.frame.hide() if not argv["dev-tools"]

bridge.on "showMyProfileWindow", ->
  launchCommand(config.profileCMD)

bridge.on "showChangePasswordWindow", ->
  launchCommand(config.passwordCMD)

bridge.on "shutdown", -> powermanager.shutdown()
bridge.on "reboot", -> powermanager.reboot()
bridge.on "logout", -> powermanager.logout()

