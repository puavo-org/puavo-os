define [
  "cs!app/view"
  "moment"
  "underscore"
], (View, moment, _) ->
  class WlanClientDetails extends View

    className: "bb-wlan-client-details"
    templateQuery: "#wlan-client-details"

    viewJSON: ->
      history = @model.history.map (e) ->
        time = moment.unix(e.timestamp)
        return (
          hostname: e.hostname
          event: e.event
          ago: time.fromNow()
          time: time.format "YYYY-MM-DD HH:mm:ss"
        )

      return {
        mac: @model.id
        history: history
      }
