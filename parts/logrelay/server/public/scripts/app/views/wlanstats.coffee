define [
  "cs!app/view"
  "moment"
  "underscore"
], (View, moment, _) ->

  class WlanStats extends View

    className: "bb-wlan-stats"
    templateQuery: "#wlan-stats"

    constructor: (opts) ->
      super
      @model.clients.on "add remove change", =>
        @render()


    formatClient: (m) ->
      time = moment.unix(m.get "relay_timestamp")
      mac: m.get "mac"
      ago: time.fromNow()
      time: time.format "YYYY-MM-DD HH:mm:ss"

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


