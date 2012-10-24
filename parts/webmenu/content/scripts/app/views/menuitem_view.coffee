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

    constructor: ->
      super

      @bindTo Application, "hideWindow", =>
        @spinner = false
        @render()

    events:
      "click": (e) ->
        @model.trigger "select", @model

        if @model.get("type") isnt "menu"
          @spinner = true
          @render()

    render: ->
      super
      # Disabled until https://github.com/appjs/appjs/issues/223 gets fixed
      # if @spinner
      #   spin @$(".thumbnail").get(0)

