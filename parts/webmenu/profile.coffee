
app = require "appjs"

console.log "Starting profile window..."

config = require "./config.json"

window = app.createWindow
  width  : 800
  height : 530
  top : 200
  showChrome: true
  disableSecurity: true
  icons  : __dirname + '/content/icons'
  url: config.profileUrl

window.on "create", ->
  title = "Opinsys - My Profile"
  window.frame.title = title
  window.frame.show()
  window.frame.focus()

window.on "close", ->
  process.exit(1)
