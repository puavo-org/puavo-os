define [
  "cs!app/application"
  "cs!app/views/menuitem_view"
  "backbone"
], (
  Application
  MenuItemView
  Backbone
)->
  describe "MenuItemView", ->

    view = null

    beforeEach ->
      view = new MenuItemView
        model: new Backbone.Model
          type: "custom"
          command: "foo"
          name: "Foo"

      view.render()

    it "is a div", ->
      expect(view.el.tagName).to.eq("DIV")

    it "has html", ->
      expect(view.$("p")).to.have.text("Foo")

    it "will emit select event on global vent", (done) ->
      Application.global.on "select", (model) ->
        expect(model.toJSON()).to.deep.eq
          type: "custom"
          command: "foo"
          name: "Foo"
        done()
      view.$("p").trigger "click"

