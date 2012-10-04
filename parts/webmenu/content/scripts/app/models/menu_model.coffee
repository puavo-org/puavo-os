define [
  "backbone"
  "underscore"
], (
  Backbone
  _
) ->

  class AbstractItemModel extends Backbone.Model
    constructor: (opts, allItems) ->
      super
      @allItems = allItems
      @allItems.add this


  class WebItemModel extends AbstractItemModel
    constructor: (opts) ->
      super

  class DesktopItemModel extends AbstractItemModel
    constructor: (opts) ->
      super

  # Only export CategoryModel. It can build other models for us
  return class MenuModel extends AbstractItemModel

    typemap =
      web: WebItemModel
      desktop: DesktopItemModel
      menu: MenuModel

    constructor: (opts, allItems) ->
      # Items will be presented as sub collection. Remove from model attributes
      super _.omit(opts, "items"), allItems

      @items = new Backbone.Collection

      for item in opts.items
        @items.add new typemap[item.type](item, allItems)


