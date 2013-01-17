
net = require "net"
config = require "./config"

rand10to60 = -> (10 + parseInt(Math.random() * 50)) * 1000

retry = ->
  # Retry connection after some timeout if logrelay disconnects us. Use random
  # timeout to somewhat balance reconnections.
  setTimeout ->
    connect(true)
  , rand10to60()

connect = (reconnect=false) ->

  client = net.connect(
    config.tcpPort
    config.host
  )

  client.on "connect", ->
    console.log "connect"

    packet = {
      type: "desktop"
      event: "bootend"
      date: Date.now()
    }

    if reconnect
      packet.reconnect = true
      console.log "reconnecting"

    client.write JSON.stringify(packet) + "\n"

  client.on "close", ->
    console.log "Connection closed. Reconnecting soon."
    retry()

  client.on "error", (err) ->
    console.log "Connection failed. Reconnecting soon."
    retry()

connect()
