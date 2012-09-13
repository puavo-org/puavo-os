
define [
  "jquery"
  "underscore"
  "backbone"
  "socket.io"
  "cs!app/models/wlanhost"
  "cs!app/views/wlan"
], ($, _, Backbone, io, WlanHost, WlanView) ->

  ORG = window.location.pathname.split("/")[1]
  $(".organisation").text ORG

  socket = io.connect()

  window.wlanHosts = {}

  socket.on "ltsp:#{ ORG }-opinsys-fi:wlan", (packet) ->
    console.info "got packet", packet

    host = wlanHosts[packet.hostname]
    if not host
      host = wlanHosts[packet.hostname] = new WlanHost id: packet.hostname
      view = new WlanView
        model: host
      view.render()
      $("body").append view.el


    host.addPacket packet

