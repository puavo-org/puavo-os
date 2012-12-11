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

    events:
      "keyup input[name=search]": (e) ->
        console.log "Do search"
        console.log $(e.target).val()
        @trigger "changeFilter", $(e.target).val()
