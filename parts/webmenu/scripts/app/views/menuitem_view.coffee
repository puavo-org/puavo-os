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
      super

      @$el.addClass "item-" + @model.get("name")
        .toLowerCase()
        .replace(/[^a-z]/g, "")

      if @isInactive()
        @$el.addClass "inactive"

      @listenTo this, "hide-window", =>
        @$img.removeClass("rotate-loading")

    events:
      "click": "open"
      "mouseover": "toggleInactiveNotify"
      "mouseout": "toggleInactiveNotify"

    elements:
      "$thumbnail": ".thumbnail"
      "$description": ".description"
      "$img": "img"

    open: ->
      if @isInactive()
        return

      if @model.get("type") is "menu"
        @bubble "open-menu", @model
      else
        @bubble "open-app", @model
        @model.incClicks()
        @$img.addClass("rotate-loading")

    toggleInactiveNotify: ->
      if @isInactive()
        @$('.inactiveNotify').toggle()

    context: ->
      json = super()
      json.menu = @model.get("type") is "menu"
      return json

    displaySelectHighlight: ->
      @$el.addClass "selectHighlight"

    hideSelectHighlight: ->
      @$el.removeClass "selectHighlight"

    scrollTo: ->
      @bubble "scrollTo", @

    isInactive: ->
      if @model.get("status") is "inactive" then true else false
