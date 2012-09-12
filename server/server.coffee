

domain = require "domain"
express = require "express"
{Db, Connection, Server} = require "mongodb"

app = express()
app.use express.bodyParser()

dbCache = {}

openDb = (orgName, cb) ->

  if db = dbCache[orgName]
    return cb null, db

  db = dbCache[orgName] = new Db( orgName,
    new Server("localhost", Connection.DEFAULT_PORT, {}),
    { native_parser:true }
  )
  db.open cb


# /log/<database name>/<MongoDB collection name>
# Logs any given POST data to given MongoDB collection.
app.post "/log/:org/:coll", (req, res) ->

  # Just respond immediately to sender. We will just log database errors.
  res.json message: "thanks"

  data = req.body
  org = req.params.org
  collName = req.params.coll

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


app.listen 8080, ->
  console.info "Server listening on 8080"
