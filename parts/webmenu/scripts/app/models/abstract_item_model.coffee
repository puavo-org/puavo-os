define [
  "backbone"
  "underscore"

  "cs!app/utils/i18n"
], (
  Backbone
  _

  i18n
) ->
  class AbstractItemModel extends Backbone.Model
    constructor: (opts, allItems) ->
      super
      if allItems
        @allItems = allItems
        @allItems.add this

    isOk: -> true

    # Return menu items contents as translated on those parts that can be
    # translated
    toTranslatedJSON: -> _.extend(@toJSON(), {
      name: i18n.pick(@get("name"))
      description: i18n.pick(@get("name"))
    })
