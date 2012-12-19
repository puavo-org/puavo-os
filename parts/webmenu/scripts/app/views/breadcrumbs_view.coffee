define [
  "backbone.viewmaster"

  "cs!app/application"
  "hbs!app/templates/breadcrumbs"
], (
  ViewMaster

  Application
  template
) ->

  ###*
  # Adds Breadcrumbs to top of app
  #
  # @class Breadcrumbs
  ###
  class Breadcrumbs extends ViewMaster

    className: "bb-breadcrumbs"

    template: template

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

