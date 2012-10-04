define [
  "cs!app/views/layout"
  "cs!app/views/menuitem_view"
  "hbs!app/templates/menuitemlist"
  "backbone"
], (
  Layout
  MenuItem
  template
  Backbone
) ->
  class MenuList extends Layout

    className: "bb-menu"

    template: template

    constructor: ->
      super

    viewJSON: ->
      return name: @model.get "name"

