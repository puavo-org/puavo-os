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

    isOk: -> true


  class LauncherModel extends AbstractItemModel
    defaults:
      "clicks": 0

    constructor: (opts) ->
      if not opts.id
        opts.id = opts.name
      super
      if clicks = localStorage[@_lsID()]
        @set "clicks", parseInt(clicks, 10)

    incClicks: ->
      @set "clicks", @get("clicks") + 1
      localStorage[@_lsID()] = @get "clicks"

    _lsID: ->
      "clicks-#{ @id }"

    resetClicks: ->
      delete localStorage[@_lsID()]

    isOk: -> !! @get("command")

  class WebItemModel extends LauncherModel

    isOk: -> !! @get("url")

  class DesktopItemModel extends LauncherModel

  # Only export Recursive MenuModel. It can build other models for us
  return class MenuModel extends AbstractItemModel

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
          @items.add model

    isOk: -> @items.size() > 0
