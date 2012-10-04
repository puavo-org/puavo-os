define [
  "cs!app/view"
  "hbs!app/templates/menuitem"
], (
  View
  template
) ->

  class MenuItemView extends View

    className: "bb-menu-item"

    template: template

    events:
      "click": (e) ->
        @model.trigger "select", @model
