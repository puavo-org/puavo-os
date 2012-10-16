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


 $.get "/menu.json", (data, status, res) =>
   if status isnt "success"
     throw new Error "failed to load menu"


    allItems = new AllItems
    menuModel = new MenuModel data, allItems

    layout = new MenuLayout
      initialMenu: menuModel
      allItems: allItems


    layout.render()
    $(".content-container").append layout.el

    bridge = new DesktopBridge
    bridge.connect(Application)

    allItems.on "select", (model) ->
      Application.trigger "open", model.toJSON()

    Application.on "show", ->
      layout.reset()
      layout.render()

    $(window).blur ->
      Application.trigger "hideWindow"


