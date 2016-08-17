
ViewMaster = require "../vendor/backbone.viewmaster"
_ = require "underscore"
$ = window.jQuery
template = require "../templates/Tabs.hbs"


class Tabs extends ViewMaster

    className: "bb-tabs"

    constructor: ->
        super
        @currentTab = 0

        @listenTo this, "reset", =>
            @currentTab = 0
            @render()

        @listenTo this, "open-logout-view", =>
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
        @bubble "open-menu", @collection.at(@currentTab), this
        @render()

    context: ->
        return {
            tabs: @collection.map (tab, index) =>
                _.extend(tab.toJSON(), {index: index, active: index is @currentTab})
        }




module.exports = Tabs
