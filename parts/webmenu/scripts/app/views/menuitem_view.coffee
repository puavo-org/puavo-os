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
        Application.global.trigger "select", @model
      "mouseenter .thumbnail": (e) ->
        Application.global.trigger "showDescription", @model
      "mouseleave .thumbnail": (e) ->
        Application.global.trigger "hideDescription", @model

