Backbone = require "backbone"
path = require "path"
_ = require "underscore"

i18n = require "../utils/i18n.coffee"

class AbstractItemModel extends Backbone.Model
    constructor: (opts, allItems) ->
        if not opts.osIconUrl
            opts.osIconUrl = normalizeIconPath(opts.osIconPath)
        super
        if allItems and @isOk()
            @allItems = allItems
            @allItems.add this

    isOk: -> !@get("hidden")

    normalizeIconPath = (p) ->
        return p if not p

        # skip if already has a protocol
        if /^[a-z]+\:.+$/.test(p)
          return p

        if p[0] is"/"
          return "file://#{ p }"

        return "file://" + path.join(__dirname, "..", p)

    # Return menu items contents as translated on those parts that can be
    # translated
    toTranslatedJSON: -> _.extend(@toJSON(), {
        name: i18n.pick(@get("name"))
        description: i18n.pick(@get("name"))
    })

module.exports = AbstractItemModel
