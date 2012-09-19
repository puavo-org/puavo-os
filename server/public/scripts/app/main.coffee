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
) -> $ ->

  org = window.location.pathname.split("/")[1]
  $(".organisation").text org

  loading = $(".loading")

  clients = new WlanClientCollection

  historySize = 2000

  loading.text "Loading #{ historySize } entries from history..."
  $.get "/log/#{ org }/wlan?limit=#{ historySize }", (logArr, status, res) ->

    if status isnt "success"
      console.info res
      throw new Error "failed to fetch previous log data"

    console.info "Loaded #{ logArr.length } entries from db"

    loading.text "Updating models..."
    for packet in logArr
      clients.update packet

    layout = new MainLayout
      clients: clients
      name: org

    layout.render()
    $("body").append layout.el

    console.info "Render complete"

    loading.text "Connecting to real time events..."

    Backbone.history.start
      pushState: true
      root: "/#{ org }/wlan/"

    socket = io.connect()

    collName = "log:#{ org }:wlan"
    console.info "Listening #{ collName }"

    socket.on collName, (packet) ->
      console.info "#{ packet.mac } #{ packet.event } to/from #{ packet.hostname }", packet
      clients.update packet

    socket.on "connect", ->
      loading.remove()
      console.info "Connected to websocket server"



