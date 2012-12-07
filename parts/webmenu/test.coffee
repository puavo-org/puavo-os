
http = require "http"
app = require "appjs"
_  = require "underscore"
ns = require "node-static"

app.serveFilesFrom __dirname + '/content'
{argv} = require("optimist")

window = app.createWindow
  width: 800
  height: 900
  url: "http://appjs/tests.html"

window.on "ready", _.once ->
  window.frame.show()

  if not argv.once
    startDevTools()

  window.addEventListener "mocha-end", (e) ->

    if e.fails.length is 0
      console.log "ALL CLIENT TESTS OK! :)"
      process.exit 0 if argv.once
    else
      console.log e.fails
      console.log "#{ e.fails.length  } tests failed! :("
      process.exit 1 if argv.once

    console.log "Debug tests on http://localhost:1234/tests.html too" if not argv.once

startDevTools = ->

  # Open webkit inspector
  window.frame.openDevTools()

  # Rerun tests on change
  require("yalr")({
    path: "content"
    port: 48939
  })

  # Serve test over http for browser based debugging
  file = new(ns.Server)('./content')
  server = http.createServer (req, res) ->
    req.on "end", -> file.serve req, res
  server.listen 1234
