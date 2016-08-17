ViewMaster = require "../vendor/backbone.viewmaster"

Application = require "../Application.coffee"
MenuItemView = require "./MenuItemView.coffee"

class Favorites extends ViewMaster

    className: "bb-favorites"

    template: require "../templates/Favorites.hbs"

    constructor: (opts) ->
        super
        @config = opts.config

        @setList()
        @listenTo this, "favorite-removed", =>
            @setList()
            @refreshViews()
        @listenTo @collection, "change:clicks", =>
            setTimeout =>
                @setList()
                @refreshViews()
            , Application.animationDuration

    setList: ->
        views = @collection.favorites().filter((m) =>

            return true if not m.get("inactiveByDeviceType")
            return m.get("inactiveByDeviceType") isnt @config.get("hostType")

        ).slice(0, @config.get("maxFavorites")).map (model) =>
            new MenuItemView model: model

        @setView ".app-list-container", views


module.exports = Favorites
