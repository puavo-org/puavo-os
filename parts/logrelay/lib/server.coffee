
dgram = require "dgram"
net = require "net"
os = require "os"
fs = require "fs"
url = require "url"

_ = require "underscore"
JSONStream = require "json-stream"

Sender = require "./sender"

config = require "/etc/puavo-logrelay.json"

USERNAME = fs.readFileSync("/etc/puavo/ldap/dn").toString().trim()
PASSWORD = fs.readFileSync("/etc/puavo/ldap/password").toString().trim()
RELAY_HOSTNAME = os.hostname()


# /etc/opinsys/desktop/puavodomain is for legacy lucid systems
for domainPath in ["/etc/puavo/domain", "/etc/opinsys/desktop/puavodomain"]
  try
    PUAVO_DOMAIN = fs.readFileSync(domainPath).toString().trim()
    break
  catch e
    continue
if not PUAVO_DOMAIN
  throw e


try
  process.setgid(config.group)
  process.setuid(config.user)
  # TODO: initgroups on next node.js release
  # http://nodejs.org/docs/v0.9.6/api/process.html#process_process_initgroups_user_extra_group
catch err
  console.error "Failed to drop privileges to #{ config.user }:#{ config.group }", err
  process.exit(1)

targetUrl = url.parse(config.target)
targetUrl.auth = "#{ USERNAME }:#{ PASSWORD }"
targetUrl = url.format(targetUrl)

###*
# Extend Object with relay metadata
#
# @param {Object} packet
# @return {Object} packet
###
extendRelayMeta = (packet) ->
  return _.extend {}, packet, {
    relay_hostname: RELAY_HOSTNAME
    relay_puavo_domain: PUAVO_DOMAIN
    relay_timestamp: Date.now()
  }


sender = new Sender(
  targetUrl
  config.initialInterval
  config.maxInterval
)


tcpServer = net.createServer (c) ->
  jsonStream = new JSONStream()

  # Client machine owning this connection
  machine = null

  jsonStream.on "data", (packet) ->

    if packet is "ping"
      return c.write("pong")


    packet = extendRelayMeta(packet)

    console.log "Packet from tcp: ", packet

    if packet.type is "desktop" and packet.event is "bootend"
      machine = packet

    if machine
      sender.send(packet)

  # When tcp connection closes asume that the client machine was shutdown.
  c.on "close", ->
    console.log "Connection closed for", machine
    endPacket = extendRelayMeta(machine)
    endPacket.event = "shutdown"
    endPacket.date = Date.now()
    sender.send(endPacket)

  c.pipe(jsonStream)


udpServer = dgram.createSocket("udp4")

udpServer.on "message", (msg, rinfo) ->

  packet = {}

  msg.toString().split("\n").forEach (line) ->
    [k, v] = line.split(":")
    return if not k

    # Turn values inside brackets [foo,bar] to arrays
    if match = v.match(/\[(.*)\]/)
      v = match[1].split(",")

    packet[k] = v

  packet = extendRelayMeta(packet)
  console.log "Packet from udp: ", packet
  sender.send(packet)

udpServer.on "listening", ->
  address = udpServer.address()
  console.log "UDP listening on #{ address.address }:#{ address.port }"

tcpServer.on "listening", ->
  address = tcpServer.address()
  console.log "TCP listening on #{ address.address }:#{ address.port }"

udpServer.bind(config.updPort)
tcpServer.listen(config.tcpPort)
