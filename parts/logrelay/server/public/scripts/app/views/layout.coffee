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

      @subViews =
        ".header": new TotalStats
          clients: @clients
          hosts: @hosts
        ".wlan-hosts": []


      @hosts.on "select", (model) =>
        console.info "select", model.id

        @subViews[".wlan-host-details"]?.remove()
        @subViews[".wlan-host-details"] = new WlanHostDetails
          model: model
        @render()


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

    eachSubView: (fn) ->
      for container, views of @subViews
        container = @$(container)
        if not _.isArray(views)
          fn container, views
        else
          fn(container, view) for view in views

    render: ->
      @eachSubView (container, view) ->
        view.$el.detach()
      super
      @eachSubView (container, view) ->
        view.render()
        container.append view.el



