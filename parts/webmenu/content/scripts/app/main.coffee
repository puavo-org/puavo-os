define [
  "cs!app/views/menulayout_view"
  "cs!app/models/menu_model"
  "cs!app/models/allitems_collection"
  "cs!app/application"
  "jquery"
  "backbone"
],
(
  MenuLayout
  MenuModel
  AllItems
  Application
  $
  Backbone
)->

  Application.bridge.on "yalr", (port) ->
    $.getScript "http://localhost:#{ port }/livereload.js"

  Application.bridge.send "html-load"

  {user, config, menu} = APP_CONFIG

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
     Application.bridge.send "open", model.toJSON()

  $(window).blur ->
   Application.bridge.send "hideWindow"

