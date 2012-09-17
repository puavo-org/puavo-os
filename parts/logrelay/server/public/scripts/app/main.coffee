define [
  "jquery"
  "underscore"
  "backbone"
  "socket.io"
  "cs!app/models/wlanhostmodel"
  "cs!app/models/wlanclientcollection"
  "cs!app/views/layout"
], (
  $,
  _,
  Backbone,
  io,
  WlanHostModel,
  ClientCollection,
  Layout
) ->

  ORG = window.location.pathname.split("/")[1]
  $(".organisation").text ORG

  clients = new ClientCollection

  layout = new Layout
    clients: clients
    name: ORG

  layout.render()
  $("body").append layout.el

  $.get "/log/#{ ORG }/wlan?limit=1000", (logArr, status, res) ->
    if status isnt "success"
      console.info res
      throw new Error "failed to fetch previous log data"

    console.info "Loaded #{ logArr.length } entries from history"
    for packet in logArr
      clients.update packet
    console.info "Render complete. Waiting for websocket events now."

    socket = io.connect()
    socket.on "ltsp:#{ ORG }-opinsys-fi:wlan", (packet) ->
      clients.update packet



