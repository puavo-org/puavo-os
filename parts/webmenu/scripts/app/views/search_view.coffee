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

    SKIP_KEYS = [9,37,38,39,40]

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
      if SKIP_KEYS.indexOf( parseInt(e.which) ) is -1
        @bubble "search", @$input.val().trim()

