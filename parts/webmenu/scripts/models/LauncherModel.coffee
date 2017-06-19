AbstractItemModel = require "./AbstractItemModel.coffee"

class LauncherModel extends AbstractItemModel
    defaults:
        "clicks": 0

    constructor: (opts, allItems) ->
        if not opts.id
            opts.id = opts.name
        super(opts, allItems)

    incClicks: ->
        @set "clicks", @get("clicks") + 1

    _lsID: ->
        "clicks-#{ @id }"

    resetClicks: ->
        @set "clicks", 0

    isOk: ->
        super() and !!@get("command")

module.exports = LauncherModel
