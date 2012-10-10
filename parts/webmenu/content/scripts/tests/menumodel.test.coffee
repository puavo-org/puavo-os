define [
  "cs!app/models/menu_model"
  "backbone"
],
(
  MenuModel
  Backbone
)->

  data =
    type: "menu"
    name: "Top"
    items: [
      type: "desktop"
      name: "gimp"
      command: ["gimp"]
    ]


  describe "MenuModel", ->

    allItems = null
    model = null

    beforeEach ->
      allItems = new Backbone.Collection
      model = new MenuModel data, allItems
      allItems.each (m) -> m.resetClicks?()

    it "will add items to the collection", ->
      expect(allItems.size()).to.eq 2

    it "will adds items as collection", ->
      expect(model).to.have.property "items"
      expect(model.get("item")).to.be.a("undefined")

    it "will increase click count on a 'select' event", (done) ->
      item = allItems.at(1)
      item.trigger "select"
      setTimeout ->
        expect(item.get "clicks").to.eq 1
        done()
      , 1

