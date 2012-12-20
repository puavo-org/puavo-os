define [
  "backbone"

  "cs!app/utils/navigation"
  "cs!app/views/menuitem_view"
],
(
  Backbone

  Navigation
  MenuItemView
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

  menuModels = null
  menuViews = null
  beforeEach ->
    menuModels = data.items.map (d) ->
      new Backbone.Model d

    menuViews = menuModels.map (model) ->
      new MenuItemView model: model

  describe "Navigation", ->

    describe "start", ->

      it "select() activates hilight", ->
        view = menuViews[0]
        view.displaySelectHighlight = chai.spy(view.displaySelectHighlight)
        nav = new Navigation menuViews, 3
        nav.select(view)
        expect(view.displaySelectHighlight).to.have.been.called.once

      it "is has not selected", ->
        nav = new Navigation menuViews, 3
        expect(nav.selected).to.be.not.ok

      it "next() selects first menu item", ->
        nav = new Navigation menuViews, 3
        nav.next()
        expect(nav.selected.model.get("name")).to.eq("Gimp")

      it "down() selects first menu item", ->
        nav = new Navigation menuViews, 3
        nav.down()
        expect(nav.selected.model.get("name")).to.eq("Gimp")

    describe "active", ->

      nav = null

      beforeEach ->
        nav = new Navigation menuViews, 3
        nav.next()

      it "next() selects next item", ->
        nav.next()
        expect(nav.selected.model.get("name")).to.eq("Shotwell")

      it "two next() calls selects second item", ->
        nav.next()
        nav.next()
        expect(nav.selected.model.get("name")).to.eq("Flickr")

      it "down() selects first from second row", ->
        nav.down()
        expect(nav.selected.model.get("name")).to.eq("Picasa")

      it "right() selects next item", ->
        nav.right()
        expect(nav.selected.model.get("name")).to.eq("Shotwell")

      it "left() from second item selects first", ->
        nav.right()
        nav.left()
        expect(nav.selected.model.get("name")).to.eq("Gimp")

      it "left() selects last item from first item", ->
        nav.left()
        expect(nav.selected.model.get("name")).to.eq("Flickr")

      it "left() from second row selects last item from second row", ->
        nav.down()
        nav.left()
        expect(nav.selected.model.get("name")).to.eq("Pahvi")

      it "up() deactivates selection from first row", ->
        nav.up()
        expect(nav.selected).to.be.not.ok

      it "up() from second row goes to first row", ->
        nav.down()
        nav.up()
        expect(nav.selected.model.get("name")).to.eq("Gimp")

      it "down() from last row deselects", ->
        nav.down()
        nav.down()
        nav.down()
        expect(nav.selected).to.be.not.ok

      it "right() from last column selects first item of the row", ->
        nav.right()
        nav.right()
        nav.right()
        expect(nav.selected.model.get("name")).to.eq("Gimp")

      it "right() from last column on second row selects first item of the row", ->
        nav.down()
        nav.right()
        nav.right()
        nav.right()
        expect(nav.selected.model.get("name")).to.eq("Picasa")

    describe "keys", ->

      nav = null

      beforeEach ->
        nav = new Navigation menuViews, 3

      keyDownEvent = (keycode) ->
        return {
          preventDefault: chai.spy()
          which: keycode
        }

      describe "when Navigate is not active", ->

        it "down key activates menu", ->
          nav.handleKeyEvent(keyDownEvent(Navigation.key.DOWN))
          expect(nav.isActive()).to.be.ok

        it "tab key activates menu", ->
          nav.handleKeyEvent(keyDownEvent(Navigation.key.TAB))
          expect(nav.isActive()).to.be.ok

        it "right key does not activate menu", ->
          rightKeyEvent = keyDownEvent(Navigation.key.RIGHT)
          nav.handleKeyEvent(rightKeyEvent)
          expect(nav.isActive()).to.not.be.ok
          expect(rightKeyEvent.preventDefault).to.not.have.been.called.once

        it "left key does not activate menu", ->
          leftKeyEvent = keyDownEvent(Navigation.key.LEFT)
          nav.handleKeyEvent(leftKeyEvent)
          expect(nav.isActive(), "not active").to.not.be.ok
          expect(
            leftKeyEvent.preventDefault,
            "no preventDefault()"
          ).to.not.have.been.called.once

        it "up key does not activate menu", ->
          upKeyEvent = keyDownEvent(Navigation.key.UP)
          nav.handleKeyEvent(upKeyEvent)
          expect(nav.isActive()).to.not.be.ok
          expect(upKeyEvent.preventDefault).to.not.have.been.called.once

      describe "when Navigate is active", ->
        beforeEach ->
          nav.handleKeyEvent(keyDownEvent(Navigation.key.DOWN))
          for method in ["up", "down", "left", "right"]
            nav[method] = chai.spy(nav[method])

        it "down key calls down() method", ->
          e = keyDownEvent(Navigation.key.DOWN)
          nav.handleKeyEvent(e)
          expect(nav.down).to.have.been.called.once
          expect(e.preventDefault).to.have.been.called.once

        it "left key calls left() method", ->
          e = keyDownEvent(Navigation.key.LEFT)
          nav.handleKeyEvent(e)
          expect(nav.left).to.have.been.called.once
          expect(e.preventDefault).to.have.been.called.once

        it "right key calls right() method", ->
          e = keyDownEvent(Navigation.key.RIGHT)
          nav.handleKeyEvent(e)
          expect(nav.right).to.have.been.called.once
          expect(e.preventDefault).to.have.been.called.once

        it "up key calls up() method", ->
          e = keyDownEvent(Navigation.key.UP)
          nav.handleKeyEvent(e)
          expect(nav.up).to.have.been.called.once
          expect(e.preventDefault).to.have.been.called.once

        it "character keys still work", ->
          e = keyDownEvent(70) # f key
          nav.handleKeyEvent(e)
          expect(e.preventDefault).to.not.have.been.called.once
