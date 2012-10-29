
define [
  "backbone"
  "underscore"
], (Backbone, Handlebars, _) ->

  # Abstract view class
  class View extends Backbone.View

    constructor: ->
      super
      @_eventBindings = []

    viewJSON: ->
      return @model.toJSON() if @model
      return {}

    render: ->
      @$el.html @template(@viewJSON())


    bindTo: (emitter, event, callback, context) ->
      context = context or this

      if typeof(callback) is "string"
        callback = this[callback]

      if not emitter or not event or not callback
        throw new Error "Bad arguments. The signature is <emitter>, <event>, <callback / callback name>, [context]"

      emitter.on event, callback, context
      binding =
        emitter: emitter
        context: context
        callback: callback
        event: event
      @_eventBindings.push binding
      return binding

    unbindAll: ->
      for binding in @_eventBindings
        binding.emitter.off(
          binding.event,
          binding.callback,
          binding.context
        )
      @_eventBindings = []

    remove: ->
      super
      @unbindAll()

