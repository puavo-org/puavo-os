define [
  "backbone"

  "cs!app/utils/navigation"
  "cs!app/views/menuitem_view"
],
(
  Backbone

  Navigation
  MenuItem
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
    ,
      type: "web"
      name: "Walma"
      url: "https://walmademo.opinsys.fi"
    ,
      type: "web"
      name: "Pahvi"
      url: "https://pahvidemo.opinsys.fi"
    ,
      type: "web"
      name: "Opinsys"
      url: "http://www.opinsys.fi"
    ]

  menuModels = data.map (d) ->
    new Backbone.Model d

  menuViews = menuModels.map (model) ->
    new MenuItemView model: model

  describe "Navigation", ->

    describe "start", ->

      it "is has not selected", ->
        nav = new Navigation menuViews, 3
        expect(nav.selected.get("name")).to.be.not.ok

      it "next() selects first menu item", ->
        nav = new Navigation menuViews, 3
        nav.next()
        expect(nav.selected.get("name")).to.eq("Gimp")

      it "down() selects first menu item", ->
        nav = new Navigation menuViews, 3
        nav.down()
        expect(nav.selected.get("name")).to.eq("Gimp")
          