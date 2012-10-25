
define [
  "cs!app/views/menulayout_view"
  "cs!app/models/menu_model"
  "cs!app/models/allitems_collection"
  "jquery"
  "backbone"
  "underscore.string"
],
(
  MenuLayout
  MenuModel
  AllItems
  $
  Backbone
  str
)->
  data =
    type: "menu"
    name: "Top"
    items: [
      type: "desktop"
      name: "Gimp"
      command: ["gimp"]
    ,
      type: "desktop"
      name: "Shotwell"
      command: ["shotwell"]
    ,
      type: "web"
      name: "Flickr"
      url: "http://flickr.com"
    ,
      type: "web"
      name: "Picasa"
      url: "http://picasa.com"
    ]

  describe "Menu Layout", ->
    allItems = null
    layout = null

    beforeEach ->
      allItems = new AllItems
      menuModel = new MenuModel data, allItems
      allItems.each (m) -> m.resetClicks?()
      layout = new MenuLayout
        initialMenu: menuModel
        allItems: allItems
      layout.render()

    it "has rendered items", ->
      expect(layout.$(".bb-menu .item-name")).to.contain('Gimp')
      expect(layout.$el).to.have(".bb-profile")

    it "has no favorites on start", ->
      expect(layout.$(".favorites .bb-menu-item").size()).to.be 0

    describe "after clicking one item", ->

      beforeEach ->
        layout.$(".bb-menu .bb-menu-item .item-name").filter(
          (i, e) -> $(e).text() is "Gimp"
        ).click()

      it "it has one favorite", ->
        expect(layout.$(".favorites .bb-menu-item").size()).to.be 1


