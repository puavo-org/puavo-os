
dgram = require "dgram"
net = require "net"
fs = require "fs"
Q = require "q"

_ = require "underscore"
JSONStream = require "json-stream"

logRelayPacketParse = require "./logrelay_packet_parse"

Sender = require "./sender"
Pinger = require "./pinger"


promiseClose = (server) ->
    d = Q.defer()
    server.once "close", d.resolve
    server.close()
    d.promise


createServer = (config) ->

    ###*
    # Extend Object with relay metadata
    #
    # @param {Object} packet
    # @return {Object} packet
    ###
    extendRelayMeta = (packet) ->
        return _.extend {}, packet, {
            relay_hostname: config.relayHostname
            relay_puavo_domain: config.puavoDomain
            relay_timestamp: Date.now()
        }

    sender = new Sender(
        config.targetUrl
        config.initialInterval or 2000
        config.maxInterval or 1000 * 30
    )

    tcpServer = net.createServer (c) ->
        # Client machine owning this connection
        machine = null

        jsonStream = new JSONStream()
        pinger = new Pinger(c, jsonStream,
            config.pingInterval,
            config.pingTimeout
        )

        handleClose = ->
            pinger.stop()
            return if not machine
            endPacket = extendRelayMeta(machine)
            endPacket.event = "shutdown"
            endPacket.date = Date.now()
            sender.send(endPacket)

        jsonStream.on "data", (packet) ->
            packet = extendRelayMeta(packet)
            console.log "Packet from tcp: ", packet

            if packet.type is "desktop" and packet.event is "bootend"
                machine = packet
                console.info "TCP connection from", machine.hostname

            # Do not relay internal packages
            if machine and packet.type isnt "internal"
                sender.send(packet)

        # When tcp connection closes asume that the client machine was shutdown.
        c.on "close", ->
            console.info "TCP connection closed for", machine?.hostname
            handleClose()

        # Destroy connection timeout
        pinger.on "timeout", ->
            console.info "Ping timeout. Destroying connection for", machine?.hostname
            c.destroy()
            handleClose()

        c.pipe(jsonStream)
        pinger.ping()

    udpServer = dgram.createSocket("udp4")


    udpServer.on "message", (data, rinfo) ->

        try
            packet = JSON.parse(data)
        catch err
            packet = logRelayPacketParse(data)

        packet = extendRelayMeta(packet)
        console.log "Packet from udp: ", packet
        sender.send(packet)

    close = ->
        Q.all([
            promiseClose(udpServer)
            promiseClose(tcpServer)
        ])

    return {
        listening: Q.all([
            Q.nsend(udpServer, "bind", config.udpPort)
            Q.nsend(tcpServer, "listen", config.tcpPort)
        ])
        close: close
    }
module.exports = createServer
