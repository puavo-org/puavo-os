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

  data =
    name: "Graphics"
    description: "pl aa pla a"
    type: "menu"
    items: [
      name: "Gimp"
      type: "desktop"
      command: "gimp"
      description: "A drawing program"
    ,
      name: "Shotwell"
      type: "desktop"
      command: "shotwell"
      description: "Viewing program"
    ,
      name: "Flickr"
      type: "web"
      url: "http://www.flickr.com/"
      description: "Share your life in photos"
    ]


  allItems = new Backbone.Collection
  menuModel = new MenuModel data, allItems

  layout = new MenuLayout
    model: menuModel


  layout.render()
  $("body").append layout.el


  console.info "main here"
  bridge = new DesktopBridge
  bridge.connect()
  $(window).blur ->
    console.log "brul"
    bridge.hideWindow()


