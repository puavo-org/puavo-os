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

  $.when(
    $.get("/menu.json")
    $.get("/user.json")
    $.get("/config.json")
  ).fail( (res, status) ->
    console.log status, res
    throw new Error "Failed to boot up app"
  ).then (menuRes, userRes, configRes) ->

    user = new Backbone.Model userRes[0]
    config = new Backbone.Model configRes[0]

    allItems = new AllItems
    menuModel = new MenuModel menuRes[0], allItems

    layout = new MenuLayout
      user: user
      config: config
      initialMenu: menuModel
      allItems: allItems


    layout.render()
    $(".content-container").append layout.el

    bridge = new DesktopBridge
    bridge.connect(Application)

    allItems.on "select", (model) ->
     if model.get("type") isnt "menu"
       Application.trigger "open", model.toJSON()


    $(window).blur ->
     Application.trigger "hideWindow"

    Application.on "reboot", ->
      alert "reboot!"

