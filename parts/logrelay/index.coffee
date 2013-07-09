
fs = require "fs"
os = require "os"
url = require "url"
_ = require "underscore"
clim = require "clim"

_write = clim.logWrite
clim.logWrite = (level, prefixes, msg) ->
    return if level is "LOG" and process.env.NODE_ENV is "production"
    _write(level, prefixes, msg)
clim(console, true)

createServer = require "./lib/server"
config = require "/etc/puavo-logrelay.json"
# config = require "./config.json"

USERNAME = fs.readFileSync("/etc/puavo/ldap/dn").toString().trim()
PASSWORD = fs.readFileSync("/etc/puavo/ldap/password").toString().trim()

config.relayHostname = os.hostname()
config.pingTimeout = 1000 * 10
config.pingInterval = 1000 * 5

console.info "Logrelay starting with target #{ config.target }"

# /etc/opinsys/desktop/puavodomain is for legacy lucid systems
err = null
for domainPath in ["/etc/puavo/domain", "/etc/opinsys/desktop/puavodomain"]
    try
        config.puavoDomain = fs.readFileSync(domainPath).toString().trim()
        break
    catch e
        err = e
        continue
if not config.puavoDomain
    throw err


try
    process.setgid(config.group)
    process.setuid(config.user)
    # TODO: initgroups on next node.js release
    # http://nodejs.org/docs/v0.9.6/api/process.html#process_process_initgroups_user_extra_group
catch err
    console.error "Failed to drop privileges to #{ config.user }:#{ config.group }", err
    process.exit(1)

console.info "Dropped to uid #{ process.getuid() } and gid #{ process.getgid() }"

targetUrl = url.parse(config.target)
targetUrl.auth = "#{ USERNAME }:#{ PASSWORD }"
targetUrl = url.format(targetUrl)
config.targetUrl = targetUrl

createServer(config).listening.done ->
    console.log "Listening", _.pick(config, "tcpPort", "updPort")

