define [
  "cs!app/desktopbridge"
  "cs!app/views/menulayout_view"
  "jquery"
  "backbone"
],
(
  DesktopBridge
  MenuLayout
  $
  Backbone
)->

  layout = new MenuLayout
  layout.render()
  $("body").append layout.el


  console.info "main here"
  bridge = new DesktopBridge
  bridge.connect()
  $(window).blur ->
    console.log "brul"
    bridge.hideWindow()


