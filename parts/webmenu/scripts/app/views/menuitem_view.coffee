define [
  "app/views/spin"
  "backbone.viewmaster"

  "hbs!app/templates/menuitem"
  "cs!app/application"
], (
  spin
  ViewMaster

  template
  Application
) ->

  class MenuItemView extends ViewMaster

    className: "bb-menu-item"

    template: template

    events:
      "click": (e) ->
        @model.trigger "select", @model

        if @model.get("type") isnt "menu"
          @spinner = true
          @render()

      "mouseenter .thumbnail": (e) ->
        Application.global.trigger "showDescription", @model
      "mouseleave .thumbnail": (e) ->
        Application.global.trigger "hideDescription", @model

