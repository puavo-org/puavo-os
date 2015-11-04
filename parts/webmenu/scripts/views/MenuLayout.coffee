
Backbone = require "backbone"
ViewMaster = require "../vendor/backbone.viewmaster"

Application = require "../Application.coffee"
Favorites = require "./Favorites.coffee"
Lightbox = require "./Lightbox.coffee"
MenuItemConfirmView = require "./MenuItemConfirmView.coffee"
MenuListView = require "./MenuListView.coffee"
SidebarView = require "./SidebarView.coffee"
Search = require "./Search.coffee"
Tabs = require "./Tabs.coffee"
FolderTitle = require "./FolderTitle.coffee"

class HostnameView extends ViewMaster
    template: (context) ->
        "<div class=machine-hostname>#{context.hostname}</div>"


class MenuLayout extends ViewMaster

    className: "bb-menu-layout"

    template: require "../templates/MenuLayout.hbs"

    constructor: (opts) ->
        super

        @allItems = opts.allItems
        @user = opts.user
        @config = opts.config
        @lightbox = null

        @folderTitle = new FolderTitle model: opts.initialMenu.items.at(0)
        @setView ".folder-title-container", @folderTitle

        @menuListView = new MenuListView
            model: opts.initialMenu.items.at(0)
            collection: opts.allItems
            config: opts.config

        @setView ".menu-list-container", @menuListView

        @search = new Search
        @hostnameView = new HostnameView model: @config
        @setView ".search-container", @search

        @tabs = new Tabs
            collection: opts.initialMenu.items
        @setView ".tabs-container", @tabs

        @sidebarView = new SidebarView(opts)
        @setView ".sidebar-container", @sidebarView

        @favorites =  new Favorites
            collection: @allItems
            config: @config
        @setView ".favorites-container", @favorites

        @listenTo this, "open-confirm", (model) =>
            @displayViewInLightbox new MenuItemConfirmView
                model: model
                config: @config

        # Lightbox is not the same DOM tree as the other views. So manually
        # proxy all message to it too
        @listenTo this, "all", (eventName, arg) =>
            if @lightbox
                @lightbox.broadcast(eventName, arg)


        # Connect search events to MenuListView
        @listenTo this, "search", (searchString) =>
            @menuListView.broadcast("search", searchString)

        @listenTo this, "open-menu", (model, sender) =>
            @menuListView.broadcast("open-menu", model, sender)
            @folderTitle.broadcast("open-menu", model, sender)

        @listenTo this, "open-root-view", =>
            @setView ".folder-title-container", @folderTitle
            @setView ".favorites-container", @favorites
            @hostnameView.detach()
            @setView ".search-container", @search
            @removeLightbox()
            @refreshViews()

        @listenTo this, "open-logout-view", =>
            @folderTitle.detach()
            @favorites.detach()
            @search.detach()
            @setView ".search-container", @hostnameView
            @menuListView.broadcast("open-logout-view")
            @tabs.broadcast("open-logout-view")
            @$(".favorites-container").empty()
            @refreshViews()


    displayViewInLightbox: (view) ->
        @menuListView.releaseKeys()
        @removeLightbox()
        @lightbox = new Lightbox
            view: view
            position: "fullscreen"
        @lightbox.parent = this
        @lightbox.render()
        @lightbox.once "close", =>
            @removeLightbox()

    removeLightbox: ->
        if @lightbox
            @menuListView.grabKeys()
            @lightbox.remove()
            @lightbox = null

module.exports = MenuLayout

