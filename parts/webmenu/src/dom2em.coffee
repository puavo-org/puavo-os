
class Dom2Em

  constructor: (domElement) ->
    @domElement = domElement

  on: (event, cb) ->
    @domElement.addEventListener event, (e) =>
      cb e.args...

  emit: (event, args...) ->
    # Force async
    process.nextTick =>
      e = new @domElement.Event event
      e.args = args

      # AppJS has few times segfaulted when dispatching large event objects.  Log
      # them properly.
      console.info "Dispatching event from node->browser '#{ event }'", args
      @domElement.dispatchEvent(e)
      console.info "...dispatch OK!"

  # TODO: removeListener


module.exports = Dom2Em
