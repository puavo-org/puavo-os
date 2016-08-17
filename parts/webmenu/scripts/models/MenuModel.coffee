Backbone = require "backbone"
_ = require "underscore"

AbstractItemModel = require "./AbstractItemModel.coffee"
LauncherModel = require "./LauncherModel.coffee"

class WebItemModel extends LauncherModel

    isOk: ->
        !!@get("url") and !@get("hidden")

class DesktopItemModel extends LauncherModel

class MenuModel extends AbstractItemModel

    typemap =
        web: WebItemModel
        webWindow: WebItemModel
        desktop: DesktopItemModel
        custom: DesktopItemModel
        menu: MenuModel

    constructor: (opts, allItems) ->
        @items = new Backbone.Collection
        for item in opts.items
            model = new typemap[item.type](item, allItems)
            if model.isOk()
                model.parent = this

                if @items.get(model.id)
                    console.error  "Menu item with id '#{ JSON.stringify(model.id) }' already exists!"

                @items.add model

        # Items will be presented as sub collection. Remove from model
        # attributes
        super _.omit(opts, "items"), allItems

    isOk: ->
        super() and @items and @items.size() > 0 and !@get("hidden")

    isTab: -> !@parent?.parent

module.exports = MenuModel
