
nodejs = window.nodejs

insertCss = require "insert-css"
insertCss(require("../styles/main.styl"))

{user, config, menu, logger} = nodejs

window.onerror = (message, file, line, column, errorObj) ->
    logger.emit(
        msg: "unhandled exception"
        capturedFrom: "window.onerror"
        error:
            message: message
            file: file
            line: line
    )


$ = require "./vendor/jquery.shim"
Backbone = require "backbone"
Backbone.$ = $
Q = require "q"

Application = require "./Application.coffee"
MenuLayout = require "./views/MenuLayout.coffee"
AllItems = require "./models/AllItems.coffee"
MenuModel = require "./models/MenuModel.coffee"



user = new Backbone.Model user
config = new Backbone.Model config
allItems = new AllItems
menuModel = new MenuModel menu, allItems


layout = new MenuLayout
    user: user
    config: config
    initialMenu: menuModel
    allItems: allItems


# Convert selected menu item models to CMD Events
# https://github.com/opinsys/webmenu/blob/master/docs/menujson.md
hideTimer = null
layout.on "open-app", (model) ->
    # This will be send to node and node-webkit handlers
    nodejs.open(model.toTranslatedJSON())

    # Hide window after animation as played for few seconds or when the
    # opening app steals focus
    hideTimer = setTimeout ->
        nodejs.hideWindow()
    , Application.animationDuration

# Disable DOM element dragging and text selection if target is not an input
$(window).on "mousedown", (e) ->
    if e.target.tagName not in ["INPUT", "SELECT", "OPTION", "TEXTAREA"]
        e.preventDefault()

$(window).keydown (e) ->
    if e.which is 27 # Esc
        nodejs.hideWindow()

# Hide window when focus is lost
$(window).blur ->
    # Clear hideTimer on blur to avoid unwanted hiding if user immediately
    # spawns menu again
    clearTimeout(hideTimer)
    nodejs.hideWindow()
    layout.broadcast("hide-window")

layout.render()
$ -> $("body").html layout.el

nodejs.on "open-view", (viewName) ->
    layout.broadcast("reset")
    if viewName
        layout.broadcast("open-#{ viewName }-view")

layout.on "logout-action", (actionView) ->
    # Send possible feedback before logging out
    actionView.model.send().finally ->
        layout.broadcast("reset") # required when devtools is active
        nodejs.hideWindow()
        nodejs.executeAction(actionView.action)

nodejs.logReady()
