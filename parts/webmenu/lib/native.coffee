
{spawn} = require "child_process"

posix = require "posix"
mkdirp = require "mkdirp"
fs = require "fs"

launchCommand = require "./launchcommand"
menutools = require "./menutools"
powermanager = require "./powermanager"
requirefallback = require "./requirefallback"

webmenuHome = process.env.HOME + "/.config/webmenu"
spawnPipePath = webmenuHome + "/spawnmenu"
mkdirp.sync(webmenuHome)

# TODO: parse cli args when node-webkit 0.3.6 is released
# https://github.com/rogerwang/node-webkit/commit/aed7590d7ae44994391c5dc79f398125b8f0504b
argv =
  hide: true

locale = process.env.LANG
locale = "fi_FI.UTF-8"
menuJSON = requirefallback(
  webmenuHome + "/menu.json"
  "/etc/webmenu/menu.json"
  __dirname + "/../menu.json"
)

config = requirefallback(
  webmenuHome + "/config.json"
  "/etc/webmenu/config.json"
  __dirname + "/../config.json"
)


if process.env.NODE_ENV isnt "production"
  config.production = false
else
  config.production = true

menutools.injectDesktopData(
  menuJSON
  config.dotDesktopSearchPaths
  locale
  config.iconSearchPaths
  config.fallbackIcon
)

# Set puavoDomain if domain file found
try
  puavoDomain = fs.readFileSync("/etc/puavo/domain").toString()
catch err
  console.log "WARN: ", "/etc/puavo/domain file not found"

# Inject passworCMD configuration if puavoDomain is define
if puavoDomain
  if config.passwordCMD?
    config.passwordCMD.url = "https://#{puavoDomain}/users/password/own"

username = posix.getpwnam(posix.geteuid()).name
userData = posix.getpwnam(username)
userData.fullName = userData.gecos.split(",")[0]

spawnEmitter = require("./spawnmenu")(spawnPipePath)

menuWindowDisplayStatus = false

module.exports = (gui, bridge) ->

  Window = gui.Window.get()

  if process.env.devtools
    process.env.nohide = 1
    config.devtools = true
    Window.showDevTools()

  displayMenu = ->
    console.log "Displaying menu"
    menuWindowDisplayStatus = true
    bridge.trigger "spawn-menu"
    Window.show()
    Window.focus()

    # Force window activation
    setTimeout ->
      wmctrl = spawn("wmctrl", ["-F", "-R", "Webmenu"])
      wmctrl.on 'exit', (code) ->
        if code isnt 0
          console.info('wmctrl exited with code ' + code)
    , 100

  hideWindow = ->
    if process.env.nohide
      console.log "Hiding disabled"
      return
    console.info "Hiding menu window"
    if argv.hide
      menuWindowDisplayStatus = false
      Window.hide()
    else
      console.warn "Not hiding window because --no-hide is set or implied by devtools"

  toggleMenu = ->
    if menuWindowDisplayStatus then hideWindow() else displayMenu()


  spawnEmitter.on "spawn", ->
    console.info "Opening (or close) menu from webmenu-spawn"
    toggleMenu()

  bridge.on "open", (cmd) ->
    console.log "Opening command", cmd

    # Use node-webkit to open toolbarless web window
    if cmd.type is "webWindow"
      gui.Window.open? cmd.url,
        width: cmd.width or 1000
        height: cmd.height or 800
        "always-on-top": false
        toolbar: false
        frame: true
    else
      launchCommand(cmd)


  bridge.on "hide-window", ->
    hideWindow()

  bridge.on "shutdown", ->
    powermanager.shutdown()
  bridge.on "reboot", ->
    powermanager.restart()
  bridge.on "logout", ->
    powermanager.logout()

  bridge.on "html-ready", ->
    console.log "Webmenu ready. Use 'webmenu-spawn' to open it"

  bridge.trigger "desktop-ready",
    user: userData,
    config: config,
    menu: menuJSON

