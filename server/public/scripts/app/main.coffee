define [
  "jquery"
  "underscore"
  "backbone"
  "socket.io"
  "cs!app/models/wlanhostmodel"
  "cs!app/models/wlanclientcollection"
  "cs!app/views/lightbox"
  "cs!app/views/mainlayout"
], (
  $,
  _,
  Backbone,
  io,
  WlanHostModel,
  WlanClientCollection,
  Lightbox,
  MainLayout
) ->

  ORG = window.location.pathname.split("/")[1]
  $(".organisation").text ORG

  clients = new WlanClientCollection

  lb = new Lightbox
  lb.renderToBody()

  $.get "/log/#{ ORG }/wlan?limit=2000", (logArr, status, res) ->

    if status isnt "success"
      console.info res
      throw new Error "failed to fetch previous log data"

    console.info "Loaded #{ logArr.length } entries from db"

    for packet in logArr
      clients.update packet

    layout = new MainLayout
      clients: clients
      name: ORG

    layout.render()
    $("body").append layout.el

    console.info "Render complete"

    socket = io.connect()
    socket.on "ltsp:#{ ORG }-opinsys-fi:wlan", (packet) ->
      console.info "#{ packet.mac } #{ packet.event } to/from #{ packet.hostname }"
      clients.update packet
    socket.on "connect", ->
      console.info "Connected to websocket server"



