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

    # Convert selected menu item models to CMD Events
    # https://github.com/opinsys/webmenu/blob/master/docs/menujson.md
    Application.global.on "select", (model) ->
      if model.get("type") is "menu"
        return
      # This will be send to node and node-webkit handlers
      Application.bridge.trigger "open", model.toJSON()

    Application.bridge.on "open", ->
      layout.reset()

    # Hide window when focus is lost
    $(window).blur ->
      Application.bridge.trigger "hideWindow"

    layout.render()
    $(".content-container").append layout.el
    Application.bridge.trigger "html-ready"

