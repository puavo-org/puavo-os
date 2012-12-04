define [
  "cs!app/desktopbridge"
  "cs!app/views/menulayout_view"
  "cs!app/models/menu_model"
  "cs!app/models/allitems_collection"
  "cs!app/application"
  "jquery"
  "backbone"
],
(
  DesktopBridge
  MenuLayout
  MenuModel
  AllItems
  Application
  $
  Backbone
)->

    bridge = new DesktopBridge
    bridge.connect(Application)

    Application.trigger "html-load"
    console.info "Waiting for config"

    bridge.on "config", (user, config, menu) ->

      console.log "GOT Config", user, config, menu
      user = new Backbone.Model user
      config = new Backbone.Model config
      allItems = new AllItems
      menuModel = new MenuModel menu, allItems


      layout = new MenuLayout
        user: user
        config: config
        initialMenu: menuModel
        allItems: allItems


      layout.render()
      $(".content-container").append layout.el


      allItems.on "select", (model) ->
       if model.get("type") isnt "menu"
         Application.trigger "open", model.toJSON()

      $(window).blur ->
       Application.trigger "hideWindow"

      Application.on "reboot", ->
        alert "reboot!"

