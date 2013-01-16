
dgram = require "dgram"
os = require "os"
fs = require "fs"
url = require "url"


config = require "./config.json"
Sender = require "./sender"

RELAY_HOSTNAME = os.hostname()
PUAVO_DOMAIN = fs.readFileSync("/etc/opinsys/desktop/puavodomain").toString().trim()
USERNAME = fs.readFileSync("/etc/puavo/ldap/dn").toString().trim()
PASSWORD = fs.readFileSync("/etc/puavo/ldap/password").toString().trim()

targetUrl = url.parse(config.target)
targetUrl.auth = "#{ USERNAME }:#{ PASSWORD }"
targetUrl = url.format(targetUrl)

sender = new Sender(
  targetUrl
  config.initialInterval
  config.maxInterval
)

udpserver = dgram.createSocket("udp4")

udpserver.on "message", (msg, rinfo) ->

  packet = {
    relay_hostname: RELAY_HOSTNAME
    relay_puavo_domain: PUAVO_DOMAIN
    relay_timestamp: Date.now()
  }

  msg.toString().split("\n").forEach (line) ->
    [k, v] = line.split(":")
    return if not k

    # Turn values inside brackets [foo,bar] to arrays
    if match = v.match(/\[(.*)\]/)
      v = match[1].split(",")

    packet[k] = v

  console.log "PACKET", packet
  sender.send(packet)

udpserver.on "listening", ->
  address = udpserver.address()
  console.log "Listening on #{ address.address }:#{ address.port }"

udpserver.bind(config.updPort)
