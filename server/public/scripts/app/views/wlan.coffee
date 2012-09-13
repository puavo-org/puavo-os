define [
  "cs!app/view"
  "underscore"
], (View, _) ->

  # Abstract view class
  class WlanView extends View

    className: "bb-wlan-host"

    templateQuery: "#wlan-view"

    constructor: (opts) ->
      super
      @model.clients.on "change", =>
        console.info "A Client changed"
        @render()

    viewJSON: ->
      count: @model.activeClientCount()
      name: @model.id
      clients: @model.mapActiveClients (m) ->
        mac: m.get "mac"
        time: m.get "relay_timestamp"


