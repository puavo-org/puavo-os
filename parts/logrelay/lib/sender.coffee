
request = require "request"

class Sender

  constructor: (@url, @initialInterval, @maxInterval) ->
    @queue = []
    @reset()
    @sending = false

  reset: ->
    @interval = null
    @error = false

  send: (packet) ->
    if @error or @sending
      @queue.push packet
      console.log "Putting packet to queue. Size", @queue.length
      return

    @sending = true
    request.post @url, { json: packet }, (err, res, body) =>
      @sending = false

      if err
        @error = true
        @updateInterval()
        @queue.push packet
        console.error "Failed to relay packet to #{ @url }. Waiting for #{ @interval / 1000 } sec", err

        setTimeout =>
          @error = false
          @dequeue()
        , @interval

      else
        @reset()
        @dequeue()

  dequeue: ->
    if packet = @queue.shift()
      console.log "Sending from queue. Size ", @queue.length, packet
      @send(packet)

  updateInterval: ->
    if @interval
      @interval *= 2
    else
      @interval = @initialInterval

    if @interval > @maxInterval
      @interval = @maxInterval



module.exports = Sender
