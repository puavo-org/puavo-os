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

    template: template

    events:
      "click a": (e) ->
        e.preventDefault()
        cid = $(e.target).data("cid")
        selected = @model.allItems.getByCid(cid)
        Application.global.trigger "select", selected

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

