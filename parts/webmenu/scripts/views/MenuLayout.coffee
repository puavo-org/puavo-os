
ViewMaster = require "../vendor/backbone.viewmaster"

Application = require "../Application.coffee"
Favorites = require "./Favorites.coffee"
Lightbox = require "./Lightbox.coffee"
LogoutView = require "./LogoutView.coffee"
Breadcrumbs = require "./Breadcrumbs.coffee"
MenuListView = require "./MenuListView.coffee"
ProfileView = require "./ProfileView.coffee"
Search = require "./Search.coffee"

class MenuLayout extends ViewMaster

    className: "bb-menu-layout"

    template: require "../templates/MenuLayout.hbs"

    constructor: (opts) ->
        super

        @allItems = opts.allItems
        @user = opts.user
        @config = opts.config
        @lightbox = null

        @menuListView = new MenuListView
            model: opts.initialMenu
            collection: opts.allItems

        @setView ".menu-list-container", @menuListView

        @setView ".search-container", new Search

        @breadcrumbs = new Breadcrumbs model: opts.initialMenu
        @setView ".breadcrumbs-container", @breadcrumbs

        @setView ".profile-container", new ProfileView
            model: @user
            config: @config

        @setView ".favorites-container", new Favorites
            collection: @allItems
            config: @config

        @listenTo this, "open-menu", (model, sender) =>
            # Update MenuListView when user navigates from breadcrumbs
            if sender is @breadcrumbs
                @menuListView.broadcast("open-menu", model)
            # Update breadcrums when user navigates from menu tree
            if sender isnt @breadcrumbs
                @breadcrumbs.broadcast("open-menu", model)

        # Connect search events to MenuListView
        @listenTo this, "search", (searchString) =>
            @menuListView.broadcast("search", searchString)


        @listenTo this, "reset", @removeLightbox

        @listenTo this, "open-logout-view", =>
            @displayViewInLightbox new LogoutView config: @config

    displayViewInLightbox: (view) ->
        @removeLightbox()
        @lightbox = new Lightbox
            view: view
            position: "fullscreen"
        @lightbox.parent = this
        @lightbox.render()
        @lightbox.once "close", =>
            @removeLightbox()

    removeLightbox: ->
        @lightbox?.remove()
        @lightbox = null

module.exports = MenuLayout

