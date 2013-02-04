define [
  "backbone"
  "backbone.viewmaster"

  "cs!app/models/menu_model"
  "cs!app/views/menuitem_view"
],
(
  Backbone
  ViewMaster

  MenuModel
  MenuItemView
) ->

  describe "MenuItemView", ->
    parent = null
    item = null
    beforeEach ->
      parent = new ViewMaster
      parent.template = -> "<div class=container></div>"

      model = new MenuModel
        name: "Test menu"
        type: "menu"
        items: [
          name: "Test item"
          type: "custom"
          command: "testcmd"
        ]

      item = new MenuItemView
        model: model.items.first()

      parent.appendView(".container", item)
      parent.render()

    it "MenuItemView#open() bubbles 'app-open' events only once in 250ms", (done) ->

      spy = chai.spy()
      parent.on "open-app", spy

      item.open()
      setTimeout ->
        item.open()
        expect(spy).to.have.been.called.once
        done()
      , 20

    it "MenuItemView#open() bubbles 'app-open' events twice in 300ms", (done) ->

      spy = chai.spy()
      parent.on "open-app", spy

      item.open()
      setTimeout ->
        item.open()
        expect(spy).to.have.been.called.twice
        done()
      , 300

