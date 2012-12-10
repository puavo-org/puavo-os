
{spawn} = require "child_process"

posix = require "posix"
mkdirp = require "mkdirp"

launchCommand = require "./launchcommand"
menutools = require "./menutools"
powermanager = require "./powermanager"
requirefallback = require "./requirefallback"

webmenuHome = process.env.HOME + "/.config/webmenu"
spawnPipePath = webmenuHome + "/spawnmenu"
mkdirp.sync(webmenuHome)



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
  # fork __dirname + "/watchers.js"
else
  config.production = true

menutools.injectDesktopData(
  menuJSON
  config.dotDesktopSearchPaths
  locale
)

username = posix.getpwnam(posix.geteuid()).name
userData = posix.getpwnam(username)
userData.fullName = userData.gecos.split(",")[0]

spawnEmitter = require("./spawnmenu")(spawnPipePath)

module.exports = (Window, bridge) ->


  displayMenu = ->
    console.log "DISPLAY"

    bridge.trigger "spawnMenu"
    Window.show()
    Window.focus()

    title = "Webmenu"
    setTimeout ->
      wmctrl = spawn("wmctrl", ["-a", title])
      wmctrl.on 'exit', (code) ->
        if code isnt 0
          console.info('wmctrl exited with code ' + code)
    , 100

  hideMenu = ->
    console.info "HIDE", argv
    if argv.hide
      Window.hide()
    else
      console.warn "Not hiding window because --no-hide is set or implied by devtools"


  spawnEmitter.on "spawn", ->
    console.info "Opening menu from webmenu-spawn"
    displayMenu()

  bridge.on "open", (msg) ->
    console.log "OPEN", msg
    # launchCommand(msg)
    hideMenu()

  bridge.on "openSettings", ->
    console.log "OPEN settings"
    # launchCommand(config.settingsCMD)
    hideMenu()

  bridge.on "hideWindow", ->
    hideMenu()

  bridge.on "showMyProfileWindow", ->
    console.log "show my profile"
    hideMenu()
    # launchCommand(config.profileCMD)

  bridge.on "showChangePasswordWindow", ->
    console.log "show change password"
    hideMenu()
    # launchCommand(config.passwordCMD)

  bridge.on "shutdown", ->
    console.log "shutdown"
    # powermanager.shutdown()
  bridge.on "reboot", ->
    console.log "reboot"
    # powermanager.reboot()
  bridge.on "logout", ->
    console.log "logout"
    # powermanager.logout()

  return {
    user: userData,
    config: config,
    menu: menuJSON
  }

