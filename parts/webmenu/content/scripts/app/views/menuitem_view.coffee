define [
  "cs!app/view"
  "app/views/spin"
  "hbs!app/templates/menuitem"
  "cs!app/application"
], (
  View
  spin
  template
  Application
) ->

  class MenuItemView extends View

    className: "bb-menu-item"

    template: template

    events:
      "click": (e) ->
        @model.trigger "select", @model

        if @model.get("type") isnt "menu"
          @spinner = true
          @render()

      "mouseenter .thumbnail": (e) ->
        Application.trigger "showDescription", @model
      "mouseleave .thumbnail": (e) ->
        Application.trigger "hideDescription", @model

