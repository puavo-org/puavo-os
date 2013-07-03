###*
# node.js side of things starts here and its connected with the node-webkit
# "browser" in scripts/start.js.
###

posix = require "posix"
mkdirp = require "mkdirp"
fs = require "fs"
_ = require "underscore"
Handlebars = require "handlebars"

launchCommand = require "./launchcommand"
menutools = require "./menutools"
requirefallback = require "./requirefallback"
logStartTime = require "./logStartTime"
dbus = require "./dbus"
forceFocus = require "./forceFocus"
pkg = require "../package.json"

webmenuHome = process.env.HOME + "/.config/webmenu"
spawnMenu = process.env.SPAWNMENU
spawnPipePath = webmenuHome + "/spawnmenu" + if spawnMenu then "-#{spawnMenu}" else ""
mkdirp.sync(webmenuHome)

process.on 'uncaughtException', (err) ->
    console.error err.message
    process.exit 1

spawnEmitter = require("./spawnmenu")(spawnPipePath)

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

safeRequire = (path) ->
    try
        return require(path)
    catch err
        throw err if err.code isnt "MODULE_NOT_FOUND"
        return {}

# Merge config files. Last one overrides options from previous one
config = _.extend({},
    safeRequire(__dirname + "/../config.json"),
    safeRequire("/etc/webmenu/config.json"),
    safeRequire(webmenuHome + "/config.json"),
)


config.hostType = require "./hosttype"
config.production = process.env.WM_ENV isnt "production"

try
    puavoDomain = fs.readFileSync("/etc/puavo/domain").toString().trim()
    expandVariables = (ob, attr) ->
        tmpl = Handlebars.compile(ob[attr])
        ob[attr] = tmpl(puavoDomain: puavoDomain)
catch err
    console.warn "Cannot read Puavo Domain", err
    console.warn "Disabling password and profiles buttons"
    config.passwordCMD = null
    config.profileCMD = null

if puavoDomain
    if config.passwordCMD
        expandVariables(config.passwordCMD, "url")
    if config.profileCMD
        expandVariables(config.profileCMD, "url")


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
console.log(".desktop files read took " + desktopReadTook + " seconds")

username = posix.getpwnam(posix.geteuid()).name
userData = posix.getpwnam(username)
userData.fullName = userData.gecos.split(",")[0]



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
    # Make menu visible and bring it to current desktop
    ###
    displayMenu = ->
        menuVisible = true
        console.log "Displaying menu"
        Window.show()
        Window.focus()
        Window.setAlwaysOnTop(true)
        forceFocus(pkg.window.title, 50, 100, 350, 500)

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
                if menuVisible
                    # When menu view is changing while the menu itself is still visible
                    # make sure it's hidden before the view is displayed. This ensures
                    # that the menu moves to the current cursor position. Required when
                    # user clicks the logout button from right of the panel while menu is
                    # visible on the left side.
                    Window.hide()
                    setTimeout(displayMenu, 1) # Allow menu to disappear
                else
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


    # Prevent crazy menu spawning which might cause slow machines to get stuck
    # for long periods of time
    spawnEmitter.on "spawn", _.debounce(spawnHandler, 300, true)

    spawnEmitter.listening.done ->
        dbus.registerApplication()
        logStartTime("dbus registration sent in")

    bridge.on "open", (cmd) ->
        console.log "Opening command", cmd
        Window.setAlwaysOnTop(false)

        # Use node-webkit to open toolbarless web window
        if cmd.type is "webWindow"
            console.info "Opening web window", cmd.url
            gui.Window.open? cmd.url,
                width: cmd.width or 1000
                height: cmd.height or 800
                "always-on-top": false
                toolbar: false
                frame: true
                title: cmd.name
        else
            launchCommand(cmd)


    bridge.on "hide-window", ->
        hideWindow()

    bridge.on "shutdown", ->
        launchCommand(config.shutdownCMD)
    bridge.on "reboot", ->
        launchCommand(config.restartCMD)
    bridge.on "logout", ->
        launchCommand(config.logoutCMD)
    bridge.on "lock", ->
        launchCommand(config.lockCMD)

    bridge.on "html-ready", ->
        logStartTime("Webmenu started")
        console.log "Webmenu ready. Use 'webmenu-spawn' to open it"

    # Share settings with the browser
    bridge.set({
        user: userData,
        config: config,
        menu: menuJSON
    })
    bridge.trigger "desktop-ready"
