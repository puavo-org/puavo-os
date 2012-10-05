define [
  "cs!app/desktopbridge"
  "cs!app/views/menulayout_view"
  "cs!app/models/menu_model"
  "jquery"
  "backbone"
],
(
  DesktopBridge
  MenuLayout
  MenuModel
  $
  Backbone
)->


 $.get "/menu.json", (data, status, res) =>
   if status isnt "success"
     throw new Error "failed to load menu"


    allItems = new Backbone.Collection
    menuModel = new MenuModel data, allItems

    layout = new MenuLayout
      initialMenu: menuModel
      allItems: allItems


    layout.render()
    $(".content-container").append layout.el

    console.info "main here"
    bridge = new DesktopBridge

    allItems.on "select", (model) ->
      bridge.open model

    bridge.on "show", ->
      layout.reset()
      layout.render()

    bridge.connect()
    $(window).blur ->
      console.log "brul"
      bridge.hideWindow()


