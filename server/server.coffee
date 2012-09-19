

fs = require "fs"
domain = require "domain"
http = require "http"
express = require "express"
io = require "socket.io"
stylus = require "stylus"
Mongolian = require("mongolian")

oui = require "./lib/oui"
console.info oui


config = require "./config.json"

Puavo = require "./lib/puavo"

mongo = new Mongolian
app = express()
httpServer = http.createServer(app)
sio = io.listen httpServer
sio.set('log level', 1)

db = mongo.db "ltsplog"

app.configure ->
  app.use express.bodyParser()
  app.use stylus.middleware __dirname + "/public"
  app.use express.static __dirname + "/public"


app.get "/:org/wlan*", (req, res) ->
  fs.readFile __dirname + "/views/wlan.html", (err, data) ->
    if err
      res.send err
    else
      res.send data.toString()


app.get "/log/:org/:type", (req, res) ->

  org = req.params.org
  type = req.params.type
  limit = req.query.limit or 10

  collName = "log:#{ org }:#{ type }"
  coll = db.collection collName

  # Find latest entries
  coll.find().sort({ relay_timestamp: -1 }).limit(limit).toArray (err, arr) ->

    # Send latest event as last
    arr.reverse()

    for doc in arr
      delete doc._id

    if err
      console.info "Failed to fetch #{ org }/#{ collName }"
      res.send err, 501
    else
      console.info "Fetch from #{ org }/#{ collName }"
      res.json arr


# Custom log type handlers based on the type attribute
logHandlers =
  wlan: (data) ->

    if data.mac
      data.client_hostname = puavo.lookupDeviceName(org, data.mac)
      data.client_manufacturer = oui.lookup data.mac

    if data.hostname
      if data.school_id = puavo.lookupSchoolId(org, data.hostname)
        data.school_name = puavo.lookupSchoolName(org, data.school_id)
      else
        console.info "Cannot find school id for #{ fullOrg }/#{ data.hostname }"


# /log/<database name>/<MongoDB collection name>
# Logs any given POST data to given MongoDB collection.
app.post "/log", (req, res) ->

  # Just respond immediately to sender. We will just log database errors.
  res.json message: "thanks"

  data = req.body
  fullOrg = data.relay_puavo_domain

  if match = data.relay_puavo_domain.match(/^([^\.]+)/)
    org = match[1]
  else
    console.error "Failed to parse organisation key from '#{ data.relay_puavo_domain }'"
    return

  # TODO: remove when fixed!
  if data.type is "unknown"
    data.type = "wlan"

  logHandlers[data.type](data)

  collName = "log:#{ org }:#{ data.type }"
  coll = db.collection collName



  console.info "emit #{ collName }"
  sio.sockets.emit collName, data

  d = domain.create()
  d.on "error", (err) ->
    console.error "Failed to save log data to #{ org }/#{ collName }"
    console.error err.stack

  d.run -> process.nextTick ->

    coll.insert data, (err, docs) ->
      throw err if err
      console.info "Log saved to #{ org }/#{ collName }"


puavo = new Puavo config

puavo.on "ready", ->
  httpServer.listen 8080, ->
    console.info "Server is listening on 8080"

puavo.pollStart()
