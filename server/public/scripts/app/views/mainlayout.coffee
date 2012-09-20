define [
  "cs!app/models/wlanhostmodel"
  "cs!app/views/layout"
  "cs!app/views/wlanstats"
  "cs!app/views/totalstats"
  "cs!app/views/schoolselect"
  "cs!app/router"
  "backbone"
  "underscore"
], (
  WlanHostModel
  Layout
  WlanStats
  TotalStats
  SchoolSelect
  Router
  Backbone
  _
) ->

  class MainLayout extends Layout

    className: "bb-wlan-layout"
    templateQuery: "#wlan-layout"


    constructor: (opts) ->
      super

      @clients = opts.clients
      @hosts = new Backbone.Collection

      @router = new Router
        clients: @clients
        hosts: @hosts

      @subViews =
        ".total-stats-container": new TotalStats
          model: @model
          clients: @clients
          hosts: @hosts
        ".school-select-container": new SchoolSelect
          model: @model
        ".wlan-hosts": []

      @model.on "change:title", =>
        @render()

      @clients.on "add change", (model) => @createHostFromClient model
      @clients.each (model) => @createHostFromClient model

    animateAll: ->
      for view in @subViews[".wlan-hosts"]
        view.animate()

    createHostFromClient: (client) ->

      # Create new WlanHostModel if this client introduces new Wlan Host
      if not @hosts.get(client.get("hostname"))
        hostModel = new WlanHostModel
          id: client.get("hostname")
          allClients: @clients

        @hosts.add  hostModel
        view = new WlanStats
          model: hostModel
          collection: @clients
        @subViews[".wlan-hosts"].push view
        @render()

    viewJSON: ->
      schoolName: @model.get "schoolName"
      title: @model.get "title"




