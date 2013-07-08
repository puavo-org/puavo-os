MenuModel = require "../models/MenuModel.coffee"
AllItems = require "../models/AllItems.coffee"
MenuListView = require "../views/MenuListView.coffee"

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

describe "MenuListView", ->
    menuList = null

    beforeEach ->
        allItems = new AllItems
        menuModel = new MenuModel data, allItems
        menuList = new MenuListView
            model: menuModel
            collection: allItems
        menuList.render()

    afterEach -> menuList.remove()

    it "has '.bb-menu-items", ->
        expect(menuList.$(".bb-menu-item").size()).to.eq 4


    describe "'search' event", ->

        it "deactivates navigation", ->
            menuList.navigation.deactivate = chai.spy(menuList.navigation.deactivate)
            menuList.trigger "search", "foo"
            expect(menuList.navigation.deactivate).to.have.been.called.once

        it "limits items", ->
            menuList.trigger "search", "gimp"
            expect(menuList.$(".bb-menu-item").size()).to.eq 1

        it "emty search displays current menu model", ->
            menuList.trigger "search", "gimp"
            menuList.trigger "search", ""
            expect(menuList.$(".bb-menu-item").size()).to.eq 4

    describe "'reset' event", ->
        it "display initial menu", ->
            menuList.trigger "search", "gimp"
            menuList.trigger "reset"
            expect(menuList.$(".bb-menu-item").size()).to.eq 4

        it "deactivates navigation", ->
            menuList.navigation.deactivate = chai.spy(menuList.navigation.deactivate)
            menuList.trigger "reset"
            expect(menuList.navigation.deactivate).to.have.been.called.once

