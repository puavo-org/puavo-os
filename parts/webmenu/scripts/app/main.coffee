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

  Application.bridge.on "desktop-ready", ->

    if Application.bridge.get("animate")
      $("html").addClass("animate")

    {user, config, menu} = Application.bridge.toJSON()

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
    hideTimer = null
    layout.on "open-app", (model) ->
      # This will be send to node and node-webkit handlers
      Application.bridge.trigger "open", model.toJSON()

      # Hide window after animation as played for few seconds or when the
      # opening app steals focus
      hideTimer = setTimeout ->
        Application.bridge.trigger "hide-window"
      , Application.animationDuration

    # Disable DOM element dragging and text selection if target is not an input
    $(window).mousedown (e) ->
      if e.target.tagName isnt "INPUT"
        e.preventDefault()

    $(window).keydown (e) ->
      if e.which is 27 # Esc
        Application.bridge.trigger "hide-window"

    # Hide window when focus is lost
    $(window).blur ->
      # Clear hideTimer on blur to avoid unwanted hiding if user immediately
      # spawns menu again
      clearTimeout(hideTimer)
      Application.bridge.trigger "hide-window"
      layout.broadcast("hide-window")

    layout.render()
    $("body").append layout.el

    Application.bridge.on "open-view", (viewName) ->
      console.info "broadcasting reset"
      if viewName
        console.info "broadcasting open-#{ viewName }-view"
        layout.broadcast("open-#{ viewName }-view")

    ["logout", "shutdown", "reboot"].forEach (event) ->
      Backbone.on event, ->
        Application.bridge.trigger(event)

    Application.bridge.trigger "html-ready"
