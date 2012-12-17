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
    TAP = 9

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
        Application.global.trigger "startApplication"
        @$input.val("")
        return
      else if e.which is TAP
        return

      Application.global.trigger "search", @$input.val()

    nextStartApplication: (e) ->
      console.log "KEY: ", e.which
      if e.which is TAP
        e.preventDefault()
        Application.global.trigger "nextStartApplication"
        return
      
