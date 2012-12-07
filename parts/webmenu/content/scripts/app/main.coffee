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
)->


  Application.bridge.trigger "html-load"

  {user, config, menu} = APP_CONFIG

  if not config.production
    $.getScript "http://localhost:35729/livereload.js"

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

  $(window).blur ->
    layout.reset()
    Application.bridge.trigger "hideWindow"

