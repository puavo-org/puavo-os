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


    events:
      "click": "open"

    open: ->
      if @model.get("type") is "menu"
        @bubble "open-menu", @model
      else
        @bubble "open-app", @model
        # Workaround this this with node-webkit too? https://github.com/appjs/appjs/issues/223
        setTimeout =>
          @$("img").addClass "rotate-loading"
        , 10

    elements:
      "$thumbnail": ".thumbnail"
      "$description": ".description"

    context: ->
      json = super()
      json.menu = @model.get("type") is "menu"
      return json

    displaySelectHighlight: ->
      @$el.addClass "selectHighlight"

    hideSelectHighlight: ->
      @$el.removeClass "selectHighlight"
