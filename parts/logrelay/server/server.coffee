

fs = require "fs"
domain = require "domain"
http = require "http"
express = require "express"
io = require "socket.io"
stylus = require "stylus"
Mongolian = require("mongolian")
request = require("request")

config = require "./config.json"

mongo = new Mongolian
app = express()
httpServer = http.createServer(app)
sio = io.listen httpServer
sio.set('log level', 1)

organisationDevicesByMac = {}
organisationSchoolsById = {}
organisationDevicesByHostname = {}

app.configure ->

  httpServer.listen 8080, ->
    console.info "Server is listening on 8080"

  app.use express.bodyParser()
  app.use stylus.middleware __dirname + "/public"
  app.use express.static __dirname + "/public"




app.get "/:org/wlan", (req, res) ->
  fs.readFile __dirname + "/views/wlan.html", (err, data) ->
    if err
      res.send err
    else
      res.send data.toString()


app.get "/log/:org/:coll", (req, res) ->

  org = req.params.org + "-opinsys-fi"
  collName = req.params.coll
  limit = req.query.limit or 10

  db = mongo.db org
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



# /log/<database name>/<MongoDB collection name>
# Logs any given POST data to given MongoDB collection.
app.post "/log/:org/:coll", (req, res) ->
  data = req.body
  org = req.params.org
  collName = req.params.coll

  if data["mac"] && organisationDevicesByMac[org]?[data["mac"]]?["hostname"]
    data["client_hostname"] = organisationDevicesByMac[org][data["mac"]]["hostname"]
    school_id = organisationDevicesByHostname[org][data["hostname"]]["school_id"]
    data["school_id"] = school_id
    data["school_name"] = organisationSchoolsById[org][school_id]["name"]

  # Just respond immediately to sender. We will just log database errors.
  res.json
    message: "thanks"
    organisation: org
    collection: collName

  sio.sockets.emit "ltsp:#{ org }:#{ collName }", data

  d = domain.create()
  d.on "error", (err) ->
    console.error "Failed to save log data to #{ org }/#{ collName }"
    console.error err.stack

  d.run -> process.nextTick ->

    db = mongo.db org
    coll = db.collection collName
    coll.insert data, (err, docs) ->
      throw err if err
      console.info "Log saved to #{ org }/#{ collName }"


getSchoolAndDevices = (cb) ->

  for key, value of config["organisations"] then do (key, value) ->
    console.log("Organisation: ", key)

    auth = "Basic " + new Buffer(value["username"] + ":" + value["password"]).toString("base64");

    requestCount = 2
    done = (args...) ->
      requestCount -= 1
      if requestCount is 0
        cb args...
        done = ->

    # Get schools
    request {
      url: value["puavoDomain"] + "/users/schools.json",
      headers:  {"Authorization" : auth}
    }, (error, res, body) ->
      if !error && res.statusCode == 200
        schools = JSON.parse(body)
        organisationSchoolsById[key] = {}
        console.info "Fetched #{ schools.length } schools from #{ value["puavoDomain"] }"
        for school in schools
          organisationSchoolsById[key][school.puavo_id] = {}
          organisationSchoolsById[key][school.puavo_id]["name"] = school.name
      else
        console.log("Can't connect to puavo server: ", error)
      done error

    # Get devices
    request {
      method: 'GET',
      url: value["puavoDomain"] + "/devices/devices.json",
      headers:  {"Authorization" : auth}
    }, (error, res, body) ->
      if !error && res.statusCode == 200
        devices = JSON.parse(body)
        organisationDevicesByMac[key] = {}
        console.info "Fetched #{ devices.length } devices from #{ value["puavoDomain"] }"
        organisationDevicesByHostname[key] = {}
        for device in devices
          if device["puavoSchool"]
            school_id = device.puavoSchool[0].rdns[0].puavoId
            organisationDevicesByHostname[key][ device["puavoHostname"][0] ] = {}
            organisationDevicesByHostname[key][ device["puavoHostname"][0] ]["school_id"] = school_id
          if device["macAddress"]
            organisationDevicesByMac[key][ device["macAddress"][0] ] = {}
            organisationDevicesByMac[key][ device["macAddress"][0] ]["hostname"] = device["puavoHostname"][0]
      else
        console.log("Can't connect to puavo server: ", error)

      done error



do timeOutLoop = ->
  getSchoolAndDevices ->
    setTimeout ->
      timeOutLoop()
    , config.refreshDelay

