define [
  "cs!app/models/menu_model"
  "cs!app/models/allitems_collection"
  "backbone"
],
(
  MenuModel
  AllItems
  Backbone
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
    ]

  describe "AllItems Collection", ->

    allItems = null
    beforeEach ->
      allItems = new AllItems
      new MenuModel data, allItems

      allItems.find((m) ->
        m.get("name") is "Gimp"
      ).set("clicks", 5)

      allItems.find((m) ->
        m.get("name") is "Shotwell"
      ).set("clicks", 10)

      allItems.find((m) ->
        m.get("name") is "Flickr"
      ).set("clicks", 15)

    it "can list most popular apps", ->
      favorites = allItems.favorites().map (m) -> m.get("name")
      expect(favorites).to.deep.eq ["Flickr", "Shotwell", "Gimp"]

    it "can limit the list of favorites", ->
      expect(allItems.favorites(1).length).to.eq 1
      expect(allItems.favorites(2).length).to.eq 2
      expect(allItems.favorites(10).length).to.eq 3





