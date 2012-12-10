define [
  "backbone"
], (
  Backbone
) ->

  class Dom2Bb

    constructor: (domElement) ->
      @domElement = domElement
      _.extend this, Backbone.Events
      @_domListeners = {}

      @_bbTrigger = @trigger
      @trigger = @wrapTrigger
      @_bbOn = @on
      @on = @wrapOn

    wrapOn: (event, args...) ->
      console.log "going to listen #{ event }", @_bbOn
      @initListening(event)
      @_bbOn event, args...

    initListening: (event) ->
      return if @_domListeners[event]

      @_domListeners[event] = cb = (e) =>
        console.log "HOOK"
        if e.bb
          console.log "Own event. Skip"
          return
        @_bbTrigger event, (e.args or [])...

      @domElement.addEventListener event, cb

    wrapTrigger: (event, args...) ->
      @_bbTrigger event, args...
      e = new Event event
      e.args = args
      e.bb = true

      # Force async
      setTimeout =>
        # AppJS has few times segfaulted when dispatching large event objects.  Log
        # them properly.
        console.info "Dispatching event from browser->node '#{ event }'", args
        @domElement.dispatchEvent(e)
        console.info "...dispatch OK!"
      , 0

