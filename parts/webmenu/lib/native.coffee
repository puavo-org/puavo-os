###*
# node.js side of things starts here and its connected with the node-webkit
# "browser" in scripts/start.js.
###

{exec} = require "child_process"
posix = require "posix"
mkdirp = require "mkdirp"
fs = require "fs"
_ = require "underscore"

launchCommand = require "./launchcommand"
menutools = require "./menutools"
powermanager = require "./powermanager"
requirefallback = require "./requirefallback"
dbus = require "./dbus"
pkg = require "../package.json"

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
    "osIconPath": "/usr/share/icons/Faenza/emblems/96/emblem-readonly.png"
  }


desktopReadStarted = Date.now()
# inject data from .desktop file to menuJSON.
menutools.injectDesktopData(
  menuJSON
  config.dotDesktopSearchPaths
  locale
  config.iconSearchPaths
  config.fallbackIcon
  config.hostType
)
desktopReadTook = (Date.now() - desktopReadStarted) / 1000
console.log(".desktop files read in " + desktopReadTook + " seconds")

username = posix.getpwnam(posix.geteuid()).name
userData = posix.getpwnam(username)
userData.fullName = userData.gecos.split(",")[0]

spawnEmitter = require("./spawnmenu")(spawnPipePath)


###*
# Function that connects node.js and node-webkit. We should not share any other
# variables between these two worlds to keep them decoubled.
#
# @param {Object} gui node-webkit gui object
# @param {Object} bridge Plain Backbone.js model
###
module.exports = (gui, bridge) ->

  menuVisible = false

  bridge.set({
    animate: process.env.animate
    renderBug: process.env.RENDER_BUG
  })


  if process.env.devtools
    process.env.nohide = 1
    config.devtools = true
  Window = gui.Window.get()


  ###*
  # Resize window to current screen width
  ###
  resizeToScreenWidth = ->
    rowSizes = [
      300 # 1 item
      410 # 2 items
      520 # 3 items
    ]

    heights =
      800: 0
      1280: 1
      1500: 2

    width = Window.window.screen.width

    # Dynamic size in the future? Does not work now because because sidebar
    # does not scale properly for single row view.
    # For now use 2 rows.
    height = rowSizes[2]

    # if width <= 1024
    #   height = rowSizes[2]
    # else if width <= 1280
    #   height = rowSizes[1]
    # else
    #   height = rowSizes[0]

    Window.setResizable(true)
    Window.window.resizeTo(width, height)
    Window.setResizable(false)


  resizeToScreenWidth()

  ###*
  # Move window to bottom of screen
  ###
  moveToBottomLeft = ->
    Window.window.moveTo(0, Window.window.screen.height)

  ###*
  # Use wmctrl cli tool force focus on Webmenu. Calls the wmctrl after a given
  # timeout to give it some time to appear on window lists. It will also retry
  # itself if it fails which might happen on slow or high loaded machines.
  #
  # @param {Number} nextTry timeout to wait before calling wmctrl
  # @param {Number} retries* one or more timeouts to retry
  ###
  forceFocus = (nextTry, retries...) ->
    if not nextTry
      console.error "wmctrl retries exhausted. Failed to activate Webmenu!"
      return

    setTimeout ->
      cmd = "wmctrl -F -R #{ pkg.window.title }"
      wmctrl = exec cmd, (err, stdout, stderr) ->
        if err
          console.warn "wmctrl: failed: '#{ cmd }'. Error: #{ JSON.stringify err }"
          console.warn "wmctrl: stdout: #{ stdout } stderr: #{ stderr }"
          console.warn "wmctrl: Retrying after #{ nextTry }ms"
          forceFocus(retries...)
    , nextTry

  ###*
  # Make menu visible and bring it to current desktop
  ###
  displayMenu = ->
    menuVisible = true
    console.log "Displaying menu"
    Window.show()
    Window.focus()
    moveToBottomLeft()
    forceFocus(50, 100, 350, 500)

  hideWindow = ->
    menuVisible = false
    if process.env.nohide
      console.log "Hiding disabled"
      return
    console.info "Hiding menu window"
    if argv.hide
      Window.hide()
    else
      console.warn "Not hiding window because --no-hide is set or implied by devtools"

  ###*
  # Toggle menu visibility with given view name
  #
  # @param {String} viewName
  ###
  toggleMenu = do ->
    currentView = null
    return (viewName) ->
      bridge.trigger("open-view", viewName)

      if currentView isnt viewName
        currentView = viewName
        if not menuVisible
          displayMenu()
        return

      # When view is not changing just toggle menu visibility
      if menuVisible
        hideWindow()
      else
        displayMenu()


  ###*
  # Handle menu spawns from panel and keyboard shortcuts
  #
  # @param {Object} options
  #   @param {String} options.logout Display logout view
  #   @param {String} options.webmenu-exit Exit Webmenu gracefully
  ###
  spawnHandler = (options) ->

    if options.logout
      toggleMenu("logout")
    else if options["webmenu-exit"]
      code = parseInt(options["webmenu-exit"], 10) or 0
      console.info "Exiting on user request with code #{ options["webmenu-exit"] }"
      process.exit(code)
    else
      toggleMenu("root")

    resizeToScreenWidth()

  # Prevent crazy menu spawning which might cause slow machines to get stuck
  # for long periods of time
  spawnEmitter.on "spawn", _.debounce(spawnHandler, 300, true)

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
    dbus.registerApplication()

    # Log full Webmenu startup time with everyting ready
    if process.env.WM_STARTUP_TIME
      startUpTime = (Date.now() / 1000) - parseInt(process.env.WM_STARTUP_TIME)
      console.log("Webmenu started in " + startUpTime + " seconds")

    console.log "Webmenu ready. Use 'webmenu-spawn' to open it"

  # Share settings with the browser
  bridge.set({
    user: userData,
    config: config,
    menu: menuJSON
  })
  bridge.trigger "desktop-ready"
