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

    validate: ->


  class LauncherModel extends AbstractItemModel
    defaults:
      "clicks": 0

    constructor: (opts) ->
      if not opts.id
        opts.id = opts.name
      super
      if clicks = localStorage[@_lsID()]
        @set "clicks", parseInt(clicks, 10)

      @on "select", =>
        @set "clicks", @get("clicks") + 1
        localStorage[@_lsID()] = @get "clicks"
        console.log "Click count for #{ @get "name" } is #{ @get "clicks" }"

      if not @get("name")
        console.log "creating crappy", JSON.stringify(@toJSON()), opts

    _lsID: -> "clicks-#{ @id }"

    resetClicks: ->
      delete localStorage[@_lsID()]

    validate: ->
      if not @get("command")
        return "Command is missing"

  class WebItemModel extends LauncherModel

    validate: ->
      if not @get("url")
        return "Url is missing"

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
        if model.isValid()
          @items.add model

    validate: ->
      if @items.size() is 0
        return "empty menu"
