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

    className: "bb-search"

    ENTER = 13
    TAB = 9

    constructor: ->
      super
      @search = _.debounce @search, 250
      @listenTo this, "spawnMenu", @focus

    template: template

    elements:
      "$input": "input[name=search]"

    events:
      "keyup input[name=search]": "search"
      "keydown input[name=search]": "nextStartApplication"

    focus: ->
      @$input.get(0).focus()

    search: (e) ->
      e.preventDefault()
      if e.which is ENTER
        @bubble "startApplication"
        @$input.val("")
        return
      else if e.which is TAB
        return

      @bubble "search", @$input.val()

    nextStartApplication: (e) ->
      if e.which is TAB
        e.preventDefault()
        @bubble "nextStartApplication"
        return

