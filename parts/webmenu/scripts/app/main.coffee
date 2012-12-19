define [
  "jquery"
  "backbone"
  "backbone.viewmaster"

  "cs!app/views/menulayout_view"
  "cs!app/models/menu_model"
  "cs!app/models/allitems_collection"
  "cs!app/application"
],
(
  $
  Backbone
  ViewMaster

  MenuLayout
  MenuModel
  AllItems
  Application
) ->

  ViewMaster.debug = true

  Application.bridge.on "desktop-ready", ({user, config, menu}) ->

    if config.devtools
      console.log "Loading livereload.js"
      $.getScript "http://localhost:35729/livereload.js"

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
    layout.on "open-app", (model) ->
      # This will be send to node and node-webkit handlers
      Application.bridge.trigger "open", model.toJSON()
      setTimeout ->
        Application.bridge.trigger "hide-window"
      , Application.animationDuration

    # Hide window when focus is lost
    $(window).blur ->
      Application.bridge.trigger "hide-window"

    layout.render()
    $("body").append layout.el

    layout.broadcast("spawn-menu")
    Application.bridge.on "spawn-menu", ->
      layout.broadcast("spawn-menu")

    ["logout", "shutdown", "reboot"].forEach (event) ->
      layout.on event, -> Application.bridge.trigger(event)

    Application.bridge.trigger "html-ready"
