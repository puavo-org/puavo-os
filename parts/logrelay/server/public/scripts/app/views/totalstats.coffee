define [
  "cs!app/view"
  "moment"
], (View, moment, _) ->

  class TotalStats extends View

    className: "bb-total-stats"
    templateQuery: "#total-stats"

    constructor: (opts) ->
      super
      @clients = opts.clients
      @hosts = opts.hosts

      [@model, @clients, @hosts].forEach (eventEmitter) =>
        eventEmitter.on "add change remove", =>
          @render()


    renderTimer: ->

      clearTimeout @timer if @timer

      lastJoin = @clients.max (m) ->
        if not m.isConnected()
          return "0"
        m.get("relay_timestamp")

      lastJoinSec = (Date.now() / 1000)  - parseInt(lastJoin.get("relay_timestamp"), 10)
      lastJoinSec = Math.round lastJoinSec

      if 0 > lastJoinSec
        lastJoinSec = 0

      if lastJoinSec > 60
        msg = moment.unix(lastJoin.get("relay_timestamp")).fromNow()
      else
        msg = lastJoinSec + " seconds ago"

      @$(".lastJoin").text msg

      @timer = setTimeout =>
        @timer = null
        @renderTimer()
      , 1000

    render: ->
      super
      @renderTimer()

    viewJSON: ->

      # FIXME: will fail with zero events
      firstEntry = @clients.min (m) -> m.get("relay_timestamp")

      connectedCount: @clients.activeClientCount()
      seenCount: @clients.size()
      hostCount: @hosts.size()
      eventCount: @model.get("eventCount")
      name: @model.get("name")
      logStart: moment.unix(firstEntry.get("relay_timestamp")).fromNow()

