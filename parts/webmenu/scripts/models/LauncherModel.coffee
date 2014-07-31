AbstractItemModel = require "./AbstractItemModel.coffee"

class LauncherModel extends AbstractItemModel
    defaults:
        "clicks": 0

    constructor: (opts, allItems) ->
        if not opts.id
            opts.id = opts.name
        super(opts, allItems)
        if clicks = localStorage[@_lsID()]
            @set "clicks", parseInt(clicks, 10)

    incClicks: ->
        @set "clicks", @get("clicks") + 1
        localStorage[@_lsID()] = @get "clicks"

    _lsID: ->
        "clicks-#{ @id }"

    resetClicks: ->
        @set "clicks", 0
        delete localStorage[@_lsID()]

    isOk: ->
        super() and !!@get("command")

module.exports = LauncherModel
