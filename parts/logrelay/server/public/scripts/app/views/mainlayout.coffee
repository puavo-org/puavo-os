define [
  "cs!app/models/wlanhostmodel"
  "cs!app/views/layout"
  "cs!app/views/wlanstats"
  "cs!app/views/totalstats"
  "cs!app/views/wlanhostdetails"
  "cs!app/views/lightbox"
  "backbone"
  "underscore"
], (
  WlanHostModel
  Layout
  WlanStats
  TotalStats
  WlanHostDetails
  Lightbox
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


      @hosts.on "select", (model) =>
        console.info "select", model.id

        lb = new Lightbox
          subViews:
            ".content":
              new WlanHostDetails model: model
        lb.renderToBody()


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




