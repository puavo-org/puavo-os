define [
  "cs!app/views/menuitem_view"
  "backbone"
], (
  MenuItemView
  Backbone
)->
  describe "MenuItemView", ->

    view = null

    beforeEach ->
      view = new MenuItemView
        model: new Backbone.Model
          name: "Foo"
      view.render()

    it "is a div", ->
      expect(view.el.tagName).to.eq("DIV")

    it "has html", ->
      expect(view.$("h2")).to.have.text("Foo")

    it "will emit select event on the model on click", (done) ->
      view.model.on "select", -> done()
      view.$("h2").trigger "click"

