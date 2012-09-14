define [
  "cs!app/view"
  "underscore"
], (View, _) ->

  class WlanStats extends View

    className: "bb-wlan-stats"

    templateQuery: "#wlan-view"

    constructor: (opts) ->
      super
      @model.clients.on "change", =>
        console.info "A Client changed"
        @render()


    formatClient: (m) ->
      mac: m.get "mac"
      time: m.get "relay_timestamp"

    viewJSON: ->
      connected = []
      seen = []

      @model.clients.each (m) =>
        if m.isConnected()
          connected.push @formatClient m
        else
          seen.push @formatClient m

      count: @model.activeClientCount()
      name: @model.id
      connected: connected
      seen: seen.slice(0,10)


