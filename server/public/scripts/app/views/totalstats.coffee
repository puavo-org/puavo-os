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

      [@clients, @hosts].forEach (coll) =>
        coll.on "add change remove", =>
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
      connectedCount = @clients.reduce (memo, m) ->
        if m.isConnected() then memo+1 else memo
      , 0

      firstEntry = @clients.min (m) -> m.get("relay_timestamp")


      connectedCount: connectedCount
      seenCount: @clients.size()
      hostCount: @hosts.size()
      logStart: moment.unix(firstEntry.get("relay_timestamp")).fromNow()

