
define [
  "backbone"

  "cs!app/models/abstract_item_model"
], (
  Backbone

  AbstractItemModel
) ->

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
