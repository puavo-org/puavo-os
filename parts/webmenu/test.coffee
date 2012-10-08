
{exec, spawn} = require "child_process"
{argv} = require "optimist"
app = require "appjs"


createTestWindow = (url) ->
  console.log "Creating window with #{ url }"

  window = app.createWindow
    width  : 1000
    height : 480
    top : 200
    disableSecurity: true
    disableBrowserRequire: true
    url: url

  window.on "create", ->
    window.frame.show()
    if argv["dev-tools"]
      window.frame.openDevTools()


if argv.yeti
  yeti = spawn "yeti", ["--server"]
  yeti.stdout.pipe process.stdout
  yeti.stderr.pipe process.stderr
  setTimeout ->
    createTestWindow "http://localhost:9000"
  , 1000
else
  express = require "express"
  server = express()
  server.use express.static __dirname + "/content"
  server.listen 9000, ->
    createTestWindow "http://localhost:9000/tests.html"
