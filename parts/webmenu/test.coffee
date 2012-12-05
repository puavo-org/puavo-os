
{exec, spawn} = require "child_process"
{argv} = require "optimist"
app = require "appjs"


createTestWindow = (url) ->
  console.log "Creating window with #{ url }"

  window = app.createWindow
    width  : 800
    height : 640
    top : 200
    disableSecurity: true
    disableBrowserRequire: true
    url: url

  window.on "create", ->
    window.frame.show()
    window.frame.openDevTools()

call = (cmd) ->
  process.stderr.write "Executing: '#{ cmd }'\n"
  child = exec cmd
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr

if argv["yeti-server"]
  call "yeti --server"
  setTimeout ->
    createTestWindow "http://localhost:9000"
  , 1000
else if argv.yeti
  call "yeti content/tests.html"
else if argv.node
  call "node_modules/.bin/mocha --compilers coffee:coffee-script tests/*test*"
else
  express = require "express"
  require("yalr")({
    path: "content"
    port: 48939
  })
  server = express()
  server.use express.static __dirname + "/content"
  server.listen 9001, ->
    createTestWindow "http://localhost:9001/tests.html"
