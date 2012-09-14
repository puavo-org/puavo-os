define [
  "cs!app/models/wlanhostmodel"
  "cs!app/view"
  "cs!app/views/wlanstats"
  "backbone"
  "underscore"
], (
  WlanHostModel,
  View,
  WlanStats,
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

      @clients.on "add", (model) =>

        # Create new WlanHostModel if this client introduces new Wlan Host
        if not @hosts.get(model.get("hostname"))
          @hosts.add new WlanHostModel
            id: model.get("hostname")
            allClients: @clients
            firstClient: model

      # Create stats view for every WlanHostModel
      @hosts.on "add", (model) =>
        view = new WlanStats
          model: model

        view.render()
        @$el.find(".wlan-hosts").append view.el

    viewJSON: ->
      name: @name

