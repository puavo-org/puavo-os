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

    TAB = 9

    className: "bb-search"

    constructor: ->
      super
      @search = _.debounce @search, 250
      @listenTo this, "spawnMenu", @focus

    template: template

    elements:
      "$input": "input[name=search]"

    events:
      "keyup input[name=search]": "search"

    focus: ->
      @$input.val("")
      @$input.get(0).focus()

    search: (e) ->
      if e.which isnt TAB
        @bubble "search", @$input.val().trim()

