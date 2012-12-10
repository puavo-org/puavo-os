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

  openWebWindow = (cmd) ->

    gui.Window.open cmd.url,
      width: cmd.width or 1000
      height: cmd.height or 800
      "always-on-top": false
      toolbar: false
      frame: true

  Application.bridge.on "desktop-ready", ({user, config, menu}) ->

    user = new Backbone.Model user
    config = new Backbone.Model config
    allItems = new AllItems
    menuModel = new MenuModel menu, allItems

    layout = new MenuLayout
      user: user
      config: config
      initialMenu: menuModel
      allItems: allItems

    Application.global.on "select", (model) ->
      Application.bridge.trigger "open", model.toJSON()

    Application.bridge.on "open", (cmd) ->
      if cmd.type is "menu"
        return

      layout.reset()
      if cmd.type is "webWindow"
        openWebWindow cmd

    $(window).blur ->
      Application.bridge.trigger "hideWindow"

    layout.render()
    $(".content-container").append layout.el
    Application.bridge.trigger "html-ready"

