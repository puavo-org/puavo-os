
define [
  "jquery"
  "backbone"
  "underscore.string"

  "cs!app/application"
  "cs!app/views/menulayout_view"
  "cs!app/models/menu_model"
  "cs!app/models/allitems_collection"
],
(
  $
  Backbone
  str

  Application
  MenuLayout
  MenuModel
  AllItems
) ->
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
      Application.reset()
      allItems = new AllItems
      menuModel = new MenuModel data, allItems
      allItems.each (m) -> m.resetClicks?()
      layout = new MenuLayout
        initialMenu: menuModel
        allItems: allItems
        config: new Backbone.Model
        user: new Backbone.Model
      layout.render()

    it "has menu item(s)", ->
      expect(layout.$(".bb-menu .item-name")).to.contain('Gimp')
    it "has profile view", ->
      expect(layout.$el).to.have(".bb-profile")
    it "has favorites view", ->
      expect(layout.$el).to.have(".most-used-list")

    it "has empty favorites view", ->
      expect(layout.$(".favorites .bb-menu-item").size()).to.be 0

    describe "after clicking one item", ->

      beforeEach ->

        layout.$(".bb-menu .bb-menu-item .item-name").filter(
          (i, e) -> $(e).text() is "Gimp"
        ).click()

      it "it has one favorite", ->
        expect(layout.$(".favorites .bb-menu-item").size()).to.be 1

    describe "after mouse entering item", ->

      beforeEach (done) ->
        layout.$(".bb-menu-item .thumbnail").filter(
          (i, e) -> $(e).text().trim() is "Gimp"
        ).mouseenter()
        setTimeout done, 600

      it "displays the item description", ->
        expect(layout.$el).to.have(".bb-item-description")
        expect(layout.$el).to.not.have(".bb-profile")


