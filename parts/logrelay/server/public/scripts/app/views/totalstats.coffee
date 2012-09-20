define [
  "cs!app/view"
  "moment"
  "uri"
  "underscore"
], (View, moment, URI, _) ->

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
      time = moment.unix(firstEntry.get("relay_timestamp"))

      eventCount = @model.get("eventCount")
      url = URI(window.location.href)
      moreUrl =  url.query(events: eventCount + 1000).toString()
      lessUrl =  url.query(events: Math.max(eventCount - 1000, 1000)).toString()

      connectedCount: @clients.activeClientCount()
      seenCount: @clients.size()
      hostCount: @hosts.size()
      eventCount: eventCount
      schoolName: @model.get("schoolName")
      logStart: time.format "YYYY-MM-DD HH:mm:ss"
      logStartAgo: time.fromNow()
      moreUrl:  moreUrl
      lessUrl: lessUrl

