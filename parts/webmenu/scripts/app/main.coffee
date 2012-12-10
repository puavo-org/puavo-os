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
) -> (user, config, menu) ->


  Application.bridge.trigger "html-load"


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
      layout.reset()
      Application.bridge.trigger "open", model.toJSON()

  Application.bridge.on "spawnMenu", ->
    setTimeout ->
      console.log "RESEEEEEEEEEEEEEEEEEEEEEEET"
      layout.reset()
      setTimeout ->
        window.forceRedraw(layout.menu.el)
      , 1000
    , 100

  $(window).blur ->
    layout.reset()
    setTimeout ->
      Application.bridge.trigger "hideWindow"
    , 100

