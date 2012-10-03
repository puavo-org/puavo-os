define [
  "cs!app/views/layout"
  "cs!app/views/menuitem_view"
  "hbs!app/templates/menulayout"
  "backbone"
], (
  Layout
  MenuItem
  template
  Backbone
) ->
  class MenuLayout extends Layout

    className: "bb-menu"

    template: template

    constructor: ->
      super

      @subViews[".menu-app-list"] = [
        new MenuItem
        new MenuItem
        new MenuItem
      ]
