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

    constructor: ->
      @search = _.debounce @search, 250
      super

    template: template

    elements:
      "$input": "input[name=search]"

    events:
      "keyup input[name=search]": "search"

    search: (e) ->
      if e.which in [13, 27]
        console.log "Press Enter"
        @trigger "startFirstApplication"
        return e.preventDefault()
      @trigger "changeFilter", @$input.val()

    search: ->
      Application.global.trigger "changeFilter", @$input.val()
