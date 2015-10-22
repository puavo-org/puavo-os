Backbone = require "backbone"
Application = require "../Application.coffee"
AllItems = require "../models/AllItems.coffee"
MenuModel = require "../models/MenuModel.coffee"
MenuLayout = require "../views/MenuLayout.coffee"

data =
    type: "menu"
    name: "Top"
    items: [
        type: "menu"
        name: "Tabs"
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
            type: "menu"
            name: "submenu"
            items: [
                type: "web"
                name: "Subitem"
                url: "http://example.com"
            ]
        ]
    ]

class MockFeeds extends Backbone.Collection
    fetch: ->

describe "MenuLayout", ->
    allItems = null
    layout = null

    beforeEach ->
        allItems = new AllItems
        menuModel = new MenuModel data, allItems
        allItems.each (m) -> m.resetClicks?()
        layout = new MenuLayout
            initialMenu: menuModel
            allItems: allItems
            config: new Backbone.Model
            user: new Backbone.Model
            feeds: new MockFeeds
        layout.render()

    afterEach -> layout.remove()

    it "has menu item(s)", ->
        expect(layout.$(".bb-menu-list .bb-menu-item")).to.contain('Gimp')

    it "has sidebar view", ->
        expect(layout.$el).to.have(".bb-sidebar")
    it "has favorites view", ->
        expect(layout.$el).to.have(".bb-favorites")

    it "has empty favorites view", ->
        expect(layout.$(".bb-favorites .bb-menu-item").size()).to.be 0

    describe "after clicking one item", ->

        beforeEach (done) ->
            layout.$(".bb-menu-list .bb-menu-item .item-name").filter(
                (i, e) ->
                    $(e).text().trim() is "Gimp"
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



    describe "navigation", ->
        it "opens new menu list after clicking menu item", ->
            expect(layout.$(".bb-menu-list .bb-menu-item")).to.not.contain('Subitem')
            layout.$(".bb-menu-item.type-menu").trigger("click")
            expect(layout.$(".bb-menu-list .bb-menu-item")).to.contain('Subitem')
