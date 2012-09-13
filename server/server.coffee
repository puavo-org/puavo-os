

domain = require "domain"
http = require "http"
express = require "express"
io = require "socket.io"
{Db, Connection, Server} = require "mongodb"


console.info "starting"
console.error "error testi!"

app = express()
httpServer = http.createServer(app)
sio = io.listen httpServer
console.info "sio", sio
console.info "io", io

app.configure ->

  httpServer.listen 8080, ->
    console.info "Server is listening on 8080"

  app.set "view engine", "hbs"
  app.use express.bodyParser()
  app.use express.static __dirname + "/public"


dbCache = {}

openDb = (orgName, cb) ->

  if db = dbCache[orgName]
    return cb null, db

  db = dbCache[orgName] = new Db( orgName,
    new Server("localhost", Connection.DEFAULT_PORT, {}),
    { native_parser:true }
  )
  db.open cb


app.get "/", (req, res) ->
  res.render "index", layout: false


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
    console.info "Failed to save log data to #{ org }/#{ collName }", err

  d.run -> process.nextTick ->
    openDb org, (err, db) ->
      throw err if err
      db.createCollection collName, (err, coll) ->
        throw err if err
        coll.insert data, (err, docs) ->
          throw err if err
          console.info "Log saved for #{ org }/#{ collName }", docs


