_ = require "underscore"


ViewMaster = require "../vendor/backbone.viewmaster"

class MenuItemView extends ViewMaster

    className: "bb-menu-item"

    template: require "../templates/MenuItemView.hbs"

    constructor: ->
        super

        # Make sure that single app can be opened only once in 250ms. Prevents
        # situations when holding down enter key might spawn multiple instances
        # of the same app
        @open = _.throttle(@open, 250)

        if id = @model.get("id")
            @$el.addClass("item-#{ id }")

        if @model.get("type") is "menu"
            @$el.addClass("type-menu")
        else
            # Normalize "desktop", "custom" to "app"
            @$el.addClass("type-app")

        if @isInactive()
            @$el.addClass "inactive"

        @listenTo this, "hide-window", =>
            @$img.removeClass("rotate-loading")

    events:
        "click": (e) ->
            if e.target is @deleteButton
                return
            @open()
        "mouseout": "toggleInactiveNotify"
        "mouseover": "toggleInactiveNotify"
        "click .delete": "removeFromFavorites"

    removeFromFavorites: ->
        @model.resetClicks()
        @bubble "favorite-removed"

    afterTemplate: ->
        @$thumbnail = @$(".thumbnail")
        @$description = @$(".description")
        @$img = @$("img,.cssIcon")
        @deleteButton = @$(".delete").get(0)

    open: ->

        if @isInactive()
            return

        if @model.get("type") is "menu"
            @bubble "open-menu", @model
        else if @model.get("confirm")
            @bubble "open-confirm", @model
        else
            @bubble "open-app", @model
            @model.incClicks()
            @$img.addClass("rotate-loading")

    toggleInactiveNotify: ->
        if @isInactive()
            @$('.inactiveNotify').toggle()

    context: ->
        json = super()
        json.menu = @model.get("type") is "menu"
        return json

    displaySelectHighlight: ->
        @$el.addClass "selectHighlight"

    hideSelectHighlight: ->
        @$el.removeClass "selectHighlight"

    scrollTo: ->
        @bubble "scrollTo", @

    isInactive: ->
        @model.get("status") is "inactive"

module.exports = MenuItemView
