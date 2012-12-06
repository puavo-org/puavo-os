
app = require "appjs"

app.serveFilesFrom __dirname + '/content'
{argv} = require("optimist")

window = app.createWindow
  width: 800
  height: 900
  url: "http://appjs/tests.html"

window.on "ready", ->
  window.frame.show()
  window.frame.openDevTools()

  if argv.once
    window.addEventListener "mocha-end", (e) ->
      if e.fails.length is 0
        console.log "ALL OK"
        process.exit 0
      else
        console.log e.fails
        console.log "#{ e.fails.length  } tests failed :("
        process.exit 1
  else
    require("yalr")({
      path: "content"
      port: 48939
    })

