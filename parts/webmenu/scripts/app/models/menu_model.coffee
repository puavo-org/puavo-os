define [
  "backbone"
  "underscore"

  "cs!app/models/launcher_model"
  "cs!app/models/abstract_item_model"
], (
  Backbone
  _

  LauncherModel
  AbstractItemModel
) ->

  class WebItemModel extends LauncherModel

    isOk: -> !! @get("url")

  class DesktopItemModel extends LauncherModel

  # Only export Recursive MenuModel. It can build other models for us
  class MenuModel extends AbstractItemModel

    typemap =
      web: WebItemModel
      desktop: DesktopItemModel
      custom: DesktopItemModel
      menu: MenuModel

    constructor: (opts, allItems) ->

      # Items will be presented as sub collection. Remove from model attributes
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

  return MenuModel
