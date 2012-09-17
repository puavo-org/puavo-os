define [
  "cs!app/view"
], (View, _) ->

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

    viewJSON: ->
      connectedCount = @clients.reduce (memo, m) ->
        if m.isConnected() then memo+1 else memo
      , 0

      connectedCount: connectedCount
      seenCount: @clients.size()

