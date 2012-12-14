define [
  "underscore"
  "backbone.viewmaster"

  "cs!app/views/search_result_view"

  "cs!app/application"
  "hbs!app/templates/search"
], (
  _
  ViewMaster

  SearchResult

  Application
  template
) ->
  class Search extends ViewMaster

    ENTER = 13

    constructor: ->
      @search = _.debounce @search, 250
      super

    template: template

    elements:
      "$input": "input[name=search]"

    events:
      "keyup input[name=search]": "search"

    search: (e) ->
      e.preventDefault()
      if e.which is ENTER
        Application.global.trigger "startFirstApplication"
        @$input.val("")
        return
      Application.global.trigger "search", @$input.val()

