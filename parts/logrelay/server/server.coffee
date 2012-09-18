

fs = require "fs"
domain = require "domain"
http = require "http"
express = require "express"
io = require "socket.io"
stylus = require "stylus"
Mongolian = require("mongolian")
request = require("request")

config = JSON.parse fs.readFileSync __dirname + "/config.json"

console.info "starting"
console.error "error testi!"

mongo = new Mongolian
app = express()
httpServer = http.createServer(app)
sio = io.listen httpServer
sio.set('log level', 1)

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


getSchoolAndDevices = ->
  console.log("Get schools and devices")
  for key, value of config["organisations"]
    console.log("Organisation: ")
    console.log(value)
    console.log(value["username"])
    auth = "Basic " + new Buffer(value["username"] + ":" + value["password"]).toString("base64");
    # Get schools
    request {
      url: "http://" + value["puavoDomain"] + "/users/schools.json",
      headers:  {"Authorization" : auth}
    }, (error, res, body) ->
      if !error && res.statusCode == 200
        schools = JSON.parse(body)
        console.log("Schools:")
        for school in schools
          console.log("\t" + school["name"])
      else
        console.log(res.statusCode)

    # Get devices
    console.log("http://" + value["puavoDomain"] + "/devices/devices.json")
    console.log auth
    request {
      method: 'GET',
      url: "http://" + value["puavoDomain"] + "/devices/devices.json",
      headers:  {"Authorization" : auth}
    }, (error, res, body) ->
      if !error && res.statusCode == 200
        devices = JSON.parse(body)
        console.log("Devices:")
        for device in devices
          console.log("\t" + device["puavoHostname"] )
       else
         console.log(res.statusCode)

delay = 30000

setTimeout((->
  getSchoolAndDevices()
  setTimeout arguments.callee, delay
  ), 3000)

