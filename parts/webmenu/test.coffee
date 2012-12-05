
app = require "appjs"

app.serveFilesFrom __dirname + '/content'

window = app.createWindow
  width: 800
  height: 900
  url: "http://appjs/tests.html"

window.on "create", ->
  window.frame.show()
  window.frame.openDevTools()
  require("yalr")({
    path: "content"
    port: 48939
  })

