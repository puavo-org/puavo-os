define [
  "backbone.viewmaster"

  "cs!app/views/search_result_view"

  "cs!app/application"
  "hbs!app/templates/search"
], (
  ViewMaster

  SearchResult

  Application
  template
) ->
  class Search extends ViewMaster

    template: template

    elements:
      "$input": "input[name=search]"

    events:
      "keyup input[name=search]": (e) ->
        @trigger "changeFilter", @$input.val()
