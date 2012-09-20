

fs = require "fs"
domain = require "domain"
http = require "http"
express = require "express"
io = require "socket.io"
stylus = require "stylus"
Mongolian = require "mongolian"
engines = require "consolidate"
_  = require "underscore"

oui = require "./lib/oui"
console.info oui


config = require "./config.json"

Puavo = require "./lib/puavo"

mongo = new Mongolian
puavo = new Puavo config
app = express()
httpServer = http.createServer(app)
db = mongo.db "ltsplog"
sio = io.listen httpServer

appLoad = "start"
app.configure "production", ->
  appLoad = "bundle"


app.configure ->
  sio.set('log level', 1)
  app.use express.bodyParser()
  app.use stylus.middleware __dirname + "/public"
  app.use express.static __dirname + "/public"

  app.engine "html", engines.underscore
  app.set "views", __dirname + "/views"
  app.set "view engine", "html"



app.get "/:org/:schoolId/wlan*", (req, res) ->
  res.render "wlan", appLoad: appLoad


app.get "/:org", (req, res) ->
  res.render "orgindex", appLoad: appLoad

# Return all schools in given organisation
app.get "/schools/:org", (req, res) ->
  org = req.params.org

  # At this point we have only wlan collection so we use it.
  collName = "log:#{ org }:wlan"
  coll = db.collection collName

  schools = {}

  # XXX: This will go through almost all entries in given organisation. We
  # might want to optimize this with distinct&find combo
  coll.find({
    school_id: { $exists: true }
    }, {
      school_id: 1
      school_name: 1
    }).forEach (doc) ->

      if doc.school_id
        schools[doc.school_id] = doc.school_name

    , (err) ->
      return res.send err, 501 if err
      res.json schools


# GET log history
# @query {Integer} limit
app.get "/log/:org/:schoolId/:type", (req, res) ->

  org = req.params.org
  type = req.params.type
  schoolId = req.params.schoolId
  limit = req.query.limit or 10

  collName = "log:#{ org }:#{ type }"
  coll = db.collection collName

  # Find latest entries
  coll.find( school_id: schoolId).sort({ relay_timestamp: -1 }).limit(limit).toArray (err, arr) ->

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
  wlan: (org, data) ->

    if data.mac
      data.client_hostname = puavo.lookupDeviceName(org, data.mac)
      data.client_manufacturer = oui.lookup data.mac

    if data.hostname
      if data.school_id = puavo.lookupSchoolId(org, data.hostname)
        data.school_name = puavo.lookupSchoolName(org, data.school_id)
      else
        console.error "Cannot find school id for #{ org }/#{ data.hostname }"


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
  if not data.type or data.type is "unknown"
    console.info "Unknown type or missing! #{ data.type }"
    data.type = "wlan"

  logHandlers[data.type](org, data)

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



puavo.on "ready", ->
  httpServer.listen 8080, ->
    console.info "Server is listening on 8080"

puavo.pollStart()
