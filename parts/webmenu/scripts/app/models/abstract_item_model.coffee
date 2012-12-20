define [
  "backbone"
], (
  Backbone
) ->
  class AbstractItemModel extends Backbone.Model
    constructor: (opts, allItems) ->
      super
      if allItems
        @allItems = allItems
        @allItems.add this

    isOk: -> true
