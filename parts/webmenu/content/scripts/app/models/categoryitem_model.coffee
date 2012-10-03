define [
  "backbone"
], (
  Backbone
) ->
  class CategoryModel extends Backbone.Model

    constructor: (opts) ->
      super
      @items = new Backbone.Collection

      @set {
        name: opts.data.name
        description: opts.data.description
      }

      for item in opts.data.items
        @items.add = new typemap[item.type] data: item


