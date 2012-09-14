

fs = require "fs"
domain = require "domain"
http = require "http"
express = require "express"
io = require "socket.io"
Mongolian = require("mongolian")


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
  app.use express.static __dirname + "/public"




app.get "/:org/wlan", (req, res) ->
  fs.readFile __dirname + "/views/wlan.html", (err, data) ->
    if err
      res.send err
    else
      res.send data.toString()


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


