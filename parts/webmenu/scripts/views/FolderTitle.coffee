ViewMaster = require "../vendor/backbone.viewmaster"

template = require "../templates/FolderTitle.hbs"
class FolderTitle extends ViewMaster

    className: "bb-folder-title"

    template: (context) ->
        if @searchActive
            return ""
        if @isTab()
            return ""
        return template(context)

    constructor: ->
        super
        @initial = @model
        @previous = null
        @searchActive = false

        @listenTo this, "open-menu", (model) =>
            @previous = @model
            @model = model
            @render()

        @listenTo this, "reset", =>
            @previous = null
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
            if @previous
                @bubble "open-menu", @previous, this

    isTab: -> !@model.parent?.parent


module.exports = FolderTitle

