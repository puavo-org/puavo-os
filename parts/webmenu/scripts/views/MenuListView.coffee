Backbone = require "backbone"
ViewMaster = require "../vendor/backbone.viewmaster"

Navigation = require "../utils/Navigation.coffee"
MenuItemView = require "./MenuItemView.coffee"
FeedbackModel = require "../models/FeedbackModel.coffee"
Feedback = require "./Feedback.coffee"

class MenuListView extends ViewMaster

    className: "bb-menu-list"

    template: require "../templates/MenuListView.hbs"

    constructor: (opts) ->
        super
        @config = opts.config

        @feedback = new FeedbackModel

        @feedbackView = new Feedback
            model: @feedback
            config: @config

        @initial = @model

        @setCurrent()

        @navigation = new Navigation @getMenuItemViews(), @itemCols()

        @keyHandler = (e) =>
            LEFT_ARROW = 37
            if @model.get("type") is "menu" and e.which is LEFT_ARROW and e.altKey and not @model.isTab()
                @bubble "open-menu", @model.parent, this
                return

            @navigation.cols = @itemCols()
            @navigation.handleKeyEvent(e)

        @grabKeys()


        @listenTo this, "reset", =>
            @model = @initial
            @setCurrent()
            @$el.attr("style", "")
            @refreshViews()
            @navigation.deactivate()

        @listenTo this, "open-logout-view", =>
            @releaseKeys()
            if @config.get("feedback")
                @setView ".app-list-container", @feedbackView
            else
                $(".app-list-container").empty()

            @$el.attr("style", "bottom: -100px")
            @refreshViews()
            @navigation.deactivate()

        @listenTo this, "open-menu", (model, sender) =>
            @model = model
            @setCurrent()
            @refreshViews()

        @listenTo this, "search", (searchString) =>
            if searchString
                @setItems @collection.searchFilter(searchString)
            else
                @setCurrent()
            @refreshViews()
            @navigation.deactivate()

        @listenTo this, "scrollTo", (itemView) =>
            itemBottom = itemView.$el.offset().top + itemView.$el.innerHeight()
            itemTop = itemView.$el.offset().top

            menuListTop = @$el.offset().top
            menuListBottom = @$el.offset().top + @$el.innerHeight()

            if itemBottom > menuListBottom
                @$el.scrollTop( @$el.scrollTop() + itemBottom - menuListBottom )
            else if itemTop < menuListTop
                @$el.scrollTop( @$el.scrollTop() - (menuListTop - itemTop) )

    grabKeys: ->
        @releaseKeys() # ensure no double bindings...
        Backbone.$(window).on "keydown", @keyHandler

    releaseKeys: ->
        Backbone.$(window).off "keydown", @keyHandler

    remove: ->
        super
        @releaseKeys()

    setCurrent: ->
        @setItems(@model.items.toArray())


    setItems: (models) ->
        @feedbackView.detach()
        @setView ".app-list-container", models.map (model) ->
            new MenuItemView
                model: model
        @$el.scrollTop(0)

    refreshViews: ->
        super
        @navigation.views = @getMenuItemViews()

    itemCols: ->
        if views =  @getMenuItemViews()
            return parseInt( @$el.innerWidth() / views[0].$el.innerWidth())
        else
            return 0

    getMenuItemViews: ->
        @getViews(".app-list-container")

module.exports = MenuListView
