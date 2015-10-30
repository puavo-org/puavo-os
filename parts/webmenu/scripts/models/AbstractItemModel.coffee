Backbone = require "backbone"
_ = require "underscore"

i18n = require "../utils/i18n.coffee"

class AbstractItemModel extends Backbone.Model
    constructor: (opts, allItems) ->
        super
        if allItems and @isOk()
            @allItems = allItems
            @allItems.add this

    isOk: -> !@get("hidden")

    # Return menu items contents as translated on those parts that can be
    # translated
    toTranslatedJSON: -> _.extend(@toJSON(), {
        name: i18n.pick(@get("name"))
        description: i18n.pick(@get("name"))
    })

module.exports = AbstractItemModel
