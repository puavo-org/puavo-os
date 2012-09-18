define [
  "cs!app/models/wlanhostmodel"
  "cs!app/views/layout"
  "cs!app/views/wlanstats"
  "cs!app/views/totalstats"
  "cs!app/views/detailslightbox"
  "backbone"
  "underscore"
], (
  WlanHostModel
  Layout
  WlanStats
  TotalStats
  DetailsLightbox
  Backbone
  _
) ->

  class MainLayout extends Layout

    className: "bb-wlan-layout"
    templateQuery: "#wlan-layout"


    constructor: (opts) ->
      super
      @name = opts.name

      @clients = opts.clients
      @hosts = new Backbone.Collection

      @subViews =
        ".total-stats-container": new TotalStats
          clients: @clients
          hosts: @hosts
        ".wlan-hosts": []


      @details = new DetailsLightbox
        hosts: @hosts
        clients: @clients

      @hosts.on "host-details", (model) =>
        console.info "selecting host", model.id
        @details.renderHost model


      @clients.on "add", (model) => @hostFromClient model
      @clients.each (model) => @hostFromClient model


    hostFromClient: (model) ->

      # Create new WlanHostModel if this client introduces new Wlan Host
      if not @hosts.get(model.get("hostname"))
        hostModel = new WlanHostModel
          id: model.get("hostname")
          allClients: @clients

        @hosts.add  hostModel
        view = new WlanStats
          model: hostModel
          collection: @clients
        @subViews[".wlan-hosts"].push view

    viewJSON: ->
      name: @name




