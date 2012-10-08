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


  class LauncherModel extends AbstractItemModel
    defaults:
      "clicks": 0

    constructor: (opts) ->
      super

      @on "select", =>
        @set "clicks", @get("clicks") + 1
        console.log "Click count for #{ @get "name" } is #{ @get "clicks" }"

  class WebItemModel extends LauncherModel
  class DesktopItemModel extends LauncherModel

  # Only export Recursive MenuModel. It can build other models for us
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
        model = new typemap[item.type](item, allItems)
        model.parent = this
        @items.add model





