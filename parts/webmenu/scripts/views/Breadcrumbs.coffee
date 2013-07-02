ViewMaster = require "../vendor/backbone.viewmaster"

###*
# Adds Breadcrumbs to top of app
#
# @class Breadcrumbs
###
class Breadcrumbs extends ViewMaster

    className: "bb-breadcrumbs"

    template: require "../templates/Breadcrumbs.hbs"

    constructor: ->
        super
        @initial = @model

        @listenTo this, "open-menu", (model) =>
            @model = model
            @render()

        @listenTo this, "reset", =>
            @model = @initial
            @render()

    events:
        "click a": (e) ->
            e.preventDefault()
            cid = $(e.target).data("cid")
            menu = @model.allItems.get(cid)
            @bubble "open-menu", menu, this

    context: ->
        current = @model
        crumbs = while current
            data =
                name: current.get "name"
                cid: current.cid
            current = current.parent
            data

        crumbs.reverse()

        return crumbs: crumbs

module.exports = Breadcrumbs

