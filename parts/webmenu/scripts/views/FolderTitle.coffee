ViewMaster = require "../vendor/backbone.viewmaster"
_ = require "underscore"

template = require "../templates/FolderTitle.hbs"
class FolderTitle extends ViewMaster

    className: "bb-folder-title"

    template: (context) ->
        if @searchActive
            return ""
        return template(context)

    context: ->
        console.error "Conxted is tab: #{ @isTab() }"
        return _.extend({}, super(), isTab: @isTab())


    constructor: ->
        super
        @initial = @model
        @prevStack = []
        @searchActive = false

        @listenTo this, "open-menu", (model, sender) =>
            if sender isnt this
                @prevStack.push(@model)
            @model = model
            @render()

        @listenTo this, "reset", =>
            @searchActive = false
            @prevStack = []
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
            if @prevStack.length isnt 0
                @bubble "open-menu", @prevStack.pop(), this

    # Top level menu is the tab menu. So a menu item without grandparent is a
    # tab item
    isTab: -> !@model.parent?.parent


module.exports = FolderTitle

