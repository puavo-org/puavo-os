define [
  "underscore"
  "backbone.viewmaster"

  "cs!app/application"
  "hbs!app/templates/search"
], (
  _
  ViewMaster

  Application
  template
) ->
  class Search extends ViewMaster

    ENTER = 13

    constructor: ->
      super
      @search = _.debounce @search, 250
      @listenTo Application.global, "focusSearch", @focus

    template: template

    elements:
      "$input": "input[name=search]"

    events:
      "keyup input[name=search]": "search"

    focus: ->
      @$input.get(0).focus()

    search: (e) ->
      e.preventDefault()
      if e.which is ENTER
        Application.global.trigger "startFirstApplication"
        @$input.val("")
        return
      Application.global.trigger "search", @$input.val()

