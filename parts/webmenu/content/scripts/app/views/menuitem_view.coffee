define [
  "cs!app/view"
  "hbs!app/templates/menuitem"
], (
  View
  template
) ->

  class Item extends View

    className: "bb-menu-item"

    template: template

    viewJSON: -> name: "lol"
