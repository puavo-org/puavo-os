
ViewMaster = require "../vendor/backbone.viewmaster"
_ = require "underscore"
$ = window.jQuery
template = require "../templates/Tabs.hbs"


class Tabs extends ViewMaster

    className: "bb-tabs"

    constructor: ->
        super
        @currentTab = 0
        @storedTab = 0

        @listenTo this, "reset", =>
            @currentTab = @storedTab
            @bubble "open-menu", @collection.at(@currentTab), this
            @render()

        @listenTo this, "open-logout-view", =>
            # don't reset storedTab here!
            @currentTab = -1
            @render()

    template: ->
        if @collection.size() < 2 or @currentTab is -1
            return ""
        else
            template(@context())

    events:
        "click a": "selectTab"

    selectTab: (e) ->
        @currentTab = parseInt($(e.target).data("index"), 10)
        @storedTab = @currentTab
        @bubble "open-menu", @collection.at(@currentTab), this
        @render()

    context: ->
        return {
            tabs: @collection.map (tab, index) =>
                _.extend(tab.toJSON(), {index: index, active: index is @currentTab})
        }




module.exports = Tabs
