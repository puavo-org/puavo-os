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
    type: "menu"
    name: "Top"
    items: [
      type: "menu"
      name: "Graphics"
      description: "Graphics programs"
      items: [
        type: "menu"
        name: "Raster"
        description: "Rarter apps"
        items: [
          type: "desktop"
          name: "Gimp"
          command: "gimp"
          description: "A drawing program"
        ,
          type: "desktop"
          name: "Shotwell"
          command: "shotwell"
          description: "Viewing program"
        ,
          type: "web"
          name: "Flickr"
          url: "http://www.flickr.com/"
          description: "Share your life in photos"
        ]
      ,
        type: "menu"
        name: "Vector"
        description: "Vector apps"
        items: [
          type: "desktop"
          name: "Inkscape"
          command: "inkscape"
          description: "A vector drawing program"
        ]
      ]
    ]


  allItems = new Backbone.Collection
  menuModel = new MenuModel data, allItems

  layout = new MenuLayout
    initialMenu: menuModel
    allItems: allItems


  layout.render()
  $("body").append layout.el


  console.info "main here"
  bridge = new DesktopBridge
  bridge.connect()
  $(window).blur ->
    console.log "brul"
    bridge.hideWindow()


