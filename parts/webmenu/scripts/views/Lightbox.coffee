ViewMaster = require "../vendor/backbone.viewmaster"
asEvents = require "../utils/asEvents"

class Lightbox extends ViewMaster

    className: "bb-lightbox"

    template: require "../templates/Lightbox.hbs"

    constructor: (opts) ->
        super
        @setView ".content", opts.view
        if opts.position
            @$el.addClass(opts.position)
        @listenTo this, "cancel", @remove
        @listenTo asEvents(document), "click", (e) =>
            if e.target is @$background[0]
                @remove()

    afterTemplate: ->
        @$background = @$(".background")

    remove: (opts) ->
        super
        if not opts?.silent
            @trigger "close"

    render: ->
        # Only one Lightbox can be active at once
        Lightbox.current?.remove(silent: true)

        @$el.detach()
        super
        $("body").css "overflow", "hidden"
        $("body").append @el

        Lightbox.current = this

        # Restore event binding. Why needed?
        @delegateEvents()

module.exports = Lightbox
