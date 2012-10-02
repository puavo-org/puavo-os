origLog = console.log

window.log = (msg...) ->
  # origLog.apply console, msg
  e = new Event("log")
  e.msg = msg
  window.dispatchEvent(e)

# console.log = log
# console.info = log


define [
  "cs!app/desktopbridge"
  "hbs!app/templates/hello"
  "jquery"
  "backbone"
],
(
  DesktopBridge
  hello
  $
  Backbone
)->
  debugger
  console.info "main here"
  bridge = new DesktopBridge
  bridge.connect()
  $(window).blur ->
    console.log "brul"
    bridge.hideWindow()


