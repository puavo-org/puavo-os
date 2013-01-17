
dgram = require "dgram"
os = require "os"
fs = require "fs"
url = require "url"


config = require "./config.json"
Sender = require "./sender"

config = require "./config.json"

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
