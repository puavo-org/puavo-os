
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
      expect(layout.$(".bb-menu-list .bb-menu-item")).to.contain('Gimp')

    it "has profile view", ->
      expect(layout.$el).to.have(".bb-profile")
    it "has favorites view", ->
      expect(layout.$el).to.have(".bb-favorites")

    it "has empty favorites view", ->
      expect(layout.$(".bb-favorites .bb-menu-item").size()).to.be 0

    describe "after clicking one item", ->

      beforeEach (done) ->
        layout.$(".bb-menu-list .bb-menu-item").filter(
          (i, e) -> $(e).text().trim() is "Gimp"
        ).click()
        setTimeout done, Application.animationDuration + 10

      it "it has one favorite", ->
        expect(layout.$(".bb-favorites .bb-menu-item").size()).to.eq 1


    describe "search", ->

      beforeEach ->
        search = layout.$(".search-container input[name=search]").filter(
          (i, e) -> $(e).attr("name") is "search"
        )
        search.val("gimp")
        search.keyup()

      it "has found Gimp", ->
        expect(layout.$(".bb-menu-list .bb-menu-item")).to.contain('Gimp')

      it "has not found Shotwell", ->
        expect(layout.$(".bb-menu-list .bb-menu-item")).to.not.contain('Shotwell')
