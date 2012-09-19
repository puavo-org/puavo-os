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
  # class DetailsLightbox extends Lightbox


  #   constructor: (opts) ->
  #     super
  #     @clients = opts.clients
  #     @hosts = opts.hosts

  #     @setView ".host-details-container", new WlanHostDetails
  #       model: @model

  #     @clients.on "client-details", (model) =>
  #       @setView ".client-details-container", new WlanClientDetails
  #         model: model
  #       @render()

  #   viewJSON: ->
  #     host: @model.id



