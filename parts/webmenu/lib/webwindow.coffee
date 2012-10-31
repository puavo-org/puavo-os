
app = require "appjs"

argv = require("optimist")
  .default("width", 800)
  .default("height", 530)
  .default("top", 200)
  .argv

url = argv._[0]

console.info "Starting a window with url #{ url }"

window = app.createWindow
  width: argv.width
  height: argv.height
  top: argv.top
  showChrome: true
  disableSecurity: true
  url: url

window.on "create", ->
  window.frame.title = "loading..."
  window.frame.show()
  window.frame.focus()

window.on "close", ->
  process.exit(1)
