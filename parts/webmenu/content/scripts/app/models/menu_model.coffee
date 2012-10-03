define [
  "backbone"
], (
  CategoryModel
  WebItemModel
  DesktopItemModel
  Backbone
) ->
  class MenuModel extends Backbone.Model

    constructor: (opts) ->

      @currentCategory = new CategoryModel data: opts.data

