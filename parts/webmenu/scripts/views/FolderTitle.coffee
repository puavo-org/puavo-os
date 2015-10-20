ViewMaster = require "../vendor/backbone.viewmaster"

template = require "../templates/FolderTitle.hbs"
class FolderTitle extends ViewMaster

    className: "bb-folder-title"

    template: (context) ->
        if @hidden
            return ""
        return template(context)

    constructor: ->
        super
        @initial = @model
        @previous = null
        @hidden = false

        @listenTo this, "open-menu", (model) =>
            @previous = @model
            @model = model
            if @model is @initial
                @previous = null
            @render()

        @listenTo this, "reset", =>
            @previous = null
            @model = @initial
            @render()

        @listenTo this, "search", (searchString) =>
            # Hide this widget when users searches something as it doesn't make
            # sense
            @hidden = searchString isnt ""
            @render()

    events:
        "click a": (e) ->
            e.preventDefault()
            if @previous
                @bubble "open-menu", @previous, this

    context: ->
      return {
        name: @model.get("name")
        hasPrevious: !!@previous
      }

module.exports = FolderTitle

