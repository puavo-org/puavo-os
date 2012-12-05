
class Bridge

  constructor: (name, emitter) ->
    @name = name
    @emitter = emitter
    @listeners = {}

  on: (event, cb) ->
    if not @listeners[event]
      @initListening(event)
    @listeners[event].push cb

  send: (event, args...) ->
    # process.nextTick for the browser and node.js
    setTimeout =>
      e = new @emitter.Event event
      e.name = @name
      e.args = args

      # Send event to the other side
      console.info "Dispatching event '#{ event }' #{ @name }...."
      @emitter.dispatchEvent(e)
      console.info "...dispatch OK!"

      # Also emit it in here
      @_emit event, args...
    , 0

  initListening: (event) ->
    @listeners[event] = []
    @emitter.addEventListener event, (e) =>
      if e.name is @name
        console.info "My event ignore"
        return
      console.info "GOT EVENT", event, e.args
      @_emit event, (e.args or [])...

  _emit: (event, args...) ->
    if handler = @listeners[event]
      handler.forEach (cb) -> cb args...

if define?.amd
  define [], -> Bridge
else
  module.exports = Bridge
