
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

  socket = io.connect()
  socket.on "ltsp:#{ ORG }-opinsys-fi:wlan", (packet) ->
    clients.update packet



