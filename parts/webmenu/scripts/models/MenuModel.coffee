Backbone = require "backbone"
_ = require "underscore"

AbstractItemModel = require "./AbstractItemModel.coffee"
LauncherModel = require "./LauncherModel.coffee"

class WebItemModel extends LauncherModel

    isOk: -> !! @get("url")

class DesktopItemModel extends LauncherModel

class MenuModel extends AbstractItemModel

    typemap =
        web: WebItemModel
        desktop: DesktopItemModel
        custom: DesktopItemModel
        menu: MenuModel

    constructor: (opts, allItems) ->

        # Items will be presented as sub collection. Remove from model
        # attributes
        super _.omit(opts, "items"), allItems


        @items = new Backbone.Collection

        for item in opts.items
            model = new typemap[item.type](item, allItems)
            if model.isOk()
                model.parent = this

                if @items.get(model.id)
                    console.error  "Menu item with id '#{ model.id }' already exists!"

                @items.add model

    isOk: -> @items.size() > 0

module.exports = MenuModel
