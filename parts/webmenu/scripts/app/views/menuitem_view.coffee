define [
  "app/views/spin"
  "backbone.viewmaster"

  "hbs!app/templates/menuitem"
  "app/utils/debounce"
  "cs!app/application"
], (
  spin
  ViewMaster

  template
  debounce
  Application
) ->

  class MenuItemView extends ViewMaster

    className: "bb-menu-item"

    template: template

    constructor: ->
      @delayedShowDescription = debounce =>
        @showDescription()
      , 1000
      super

    events:
      "click": (e) -> Application.global.trigger "select", @model
      "mouseenter .thumbnail": "delayedShowDescription"
      "mouseleave": ->
        @delayedShowDescription.cancel()
        @render()

    elements:
      "$thumbnail": ".thumbnail"
      "$description": ".description"


    showDescription: ->
      @$thumbnail.addClass "animated flipOutY"
      setTimeout =>
        @$description.css "display", "block"
      , 300



