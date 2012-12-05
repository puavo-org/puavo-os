
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
      @emitter.dispatchEvent(e)
    , 0

  initListening: (event) ->
    @listeners[event] = []
    @emitter.addEventListener event, (e) =>
      if e.name is @name
        console.info "My event ignore"
        return

      @listeners[event].forEach (cb) =>
        cb (e.args or [])...


if define?.amd
  define [], -> Bridge
else
  module.exports = Bridge
