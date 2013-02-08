
{spawn} = require "child_process"
posix = require "posix"
mkdirp = require "mkdirp"
fs = require "fs"
_ = require "underscore"

launchCommand = require "./launchcommand"
menutools = require "./menutools"
powermanager = require "./powermanager"
requirefallback = require "./requirefallback"
dbus = require "./dbus"

webmenuHome = process.env.HOME + "/.config/webmenu"
spawnMenu = process.env.SPAWNMENU
spawnPipePath = webmenuHome + "/spawnmenu" + if spawnMenu then "-#{spawnMenu}" else ""
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

config.hostType = require "./hosttype"
config.production = process.env.NODE_ENV isnt "production"

try
  puavoDomain = fs.readFileSync("/etc/puavo/domain").toString().trim()
catch err
  console.warn "Cannot read Puavo Domain", err
  console.warn "Disabling password button"
if puavoDomain
  config.passwordCMD = {
    type: "webWindow",
    url: "https://#{puavoDomain}/users/password/own"
    name: "Salasana",
    cssIcon: "icon-cw"
  }


menutools.injectDesktopData(
  menuJSON
  config.dotDesktopSearchPaths
  locale
  config.iconSearchPaths
  config.fallbackIcon
  config.hostType
)

username = posix.getpwnam(posix.geteuid()).name
userData = posix.getpwnam(username)
userData.fullName = userData.gecos.split(",")[0]

spawnEmitter = require("./spawnmenu")(spawnPipePath)


module.exports = (gui, bridge) ->

  Window = gui.Window.get()

  if process.env.devtools
    process.env.nohide = 1
    config.devtools = true
    Window.showDevTools()

  ###*
  # Make menu visible and bring it to current desktop
  #
  # @param {String} [viewName]
  #   Which view to display. "menu" for the root menu or "logout" for logout
  #   view
  ###
  displayMenu = (viewName="root") ->
    console.log "Displaying menu"
    bridge.trigger("spawn", viewName)
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
      Window.hide()
    else
      console.warn "Not hiding window because --no-hide is set or implied by devtools"

  rootMenuVisible = false
  toggleMenu = ->
    if rootMenuVisible
      hideWindow()
      rootMenuVisible = false
    else
      displayMenu("root")
      rootMenuVisible = true

  spawnHandler = (options) ->

    if options.logout
      displayMenu("logout")
      rootMenuVisible = false
    else
      toggleMenu()

  # Prevent crazy menu spawning which might cause slow machines to get stuck
  # for long periods of time
  spawnEmitter.on "spawn", _.throttle(spawnHandler, 300)

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
    rootMenuVisible = false

  bridge.on "shutdown", ->
    powermanager.shutdown()
  bridge.on "reboot", ->
    powermanager.restart()
  bridge.on "logout", ->
    powermanager.logout()

  bridge.on "html-ready", ->
    dbus.registerApplication()
    console.log "Webmenu ready. Use 'webmenu-spawn' to open it"

  bridge.trigger "desktop-ready",
    user: userData,
    config: config,
    menu: menuJSON
