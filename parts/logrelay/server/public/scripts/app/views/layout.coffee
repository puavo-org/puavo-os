define [
  "cs!app/models/wlanhostmodel"
  "cs!app/view"
  "cs!app/views/wlanstats"
  "cs!app/views/totalstats"
  "cs!app/views/wlanhostdetails"
  "backbone"
  "underscore"
], (
  WlanHostModel,
  View,
  WlanStats,
  TotalStats,
  WlanHostDetails,
  Backbone,
  _
) ->

  class Layout extends View

    className: "bb-wlan-layout"
    templateQuery: "#wlan-layout"

    constructor: (opts) ->
      super
      @name = opts.name
      @clients = opts.clients
      @hosts = new Backbone.Collection

      @statView = new TotalStats
        clients: @clients
        hosts: @hosts
      @wlanHostViews = []

      @clients.on "add", (model) => @hostFromClient model
      @clients.each (model) => @hostFromClient model


    hostFromClient: (model) ->

      # Create new WlanHostModel if this client introduces new Wlan Host
      if not @hosts.get(model.get("hostname"))
        hostModel = new WlanHostModel
          id: model.get("hostname")
          allClients: @clients

        @hosts.add  hostModel
        view = new WlanStats model: hostModel
        @wlanHostViews.push view

    viewJSON: ->
      name: @name

    render: ->
      super
      @statView.render()
      @$(".header").append @statView.el
      for view in @wlanHostViews
        view.render()
        @$(".wlan-hosts").append view.el

