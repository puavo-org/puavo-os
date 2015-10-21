
ViewMaster = require "../vendor/backbone.viewmaster"
_ = require "underscore"
$ = window.jQuery


class Tabs extends ViewMaster

    className: "bb-tabs"

    template: require "../templates/Tabs.hbs"

    events:
        "click a": "selectTab"

    selectTab: (e) ->
        @bubble "select-tab", @collection.at($(e.target).data("index"))

    context: ->
        return {
            tabs: @collection.map (coll, index) ->
                _.extend(coll.toJSON(), {index: index})
        }




module.exports = Tabs
