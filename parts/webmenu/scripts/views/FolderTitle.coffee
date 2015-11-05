ViewMaster = require "../vendor/backbone.viewmaster"
_ = require "underscore"

template = require "../templates/FolderTitle.hbs"
class FolderTitle extends ViewMaster

    className: "bb-folder-title"

    template: (context) ->
        if @searchActive
            return ""
        return template(context)

    context: -> _.extend({}, super(), isTab: @model.isTab())

    constructor: ->
        super
        @initial = @model
        @searchActive = false

        @listenTo this, "open-menu", (model, sender) =>
            @model = model
            @render()

        @listenTo this, "reset", =>
            @searchActive = false
            @model = @initial
            @render()

        @listenTo this, "search", (searchString) =>
            # Hide this widget when users searches something as it doesn't make
            # sense
            @searchActive = searchString isnt ""
            @render()

    events:
        "click a": (e) ->
            e.preventDefault()
            if not @model.isTab()
                @bubble "open-menu", @model.parent, this

module.exports = FolderTitle

