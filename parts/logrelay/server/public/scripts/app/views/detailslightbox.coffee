define [
  "cs!app/views/lightbox"
  "cs!app/views/wlanhostdetails"
  "cs!app/views/wlanclientdetails"
  "backbone"
  "underscore"
], (
  Lightbox
  WlanHostDetails
  WlanClientDetails
  Backbone
  _
) ->
  class DetailsLightbox extends Lightbox

    className: "bb-details-lightbox"
    templateQuery: "#details-lightbox"

    constructor: (opts) ->
      super
      @clients = opts.clients
      @hosts = opts.hosts

      @clients.on "client-details", (model) ->
        debugger

    renderHost: (model) ->
      @setView ".host-details-container", new WlanHostDetails
        model: model
      @renderToBody()


