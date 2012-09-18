define [
  "cs!app/view"
  "moment"
  "underscore"
], (View, moment, _) ->
  class WlanClientDetails extends View

    className: "bb-wlan-client-details"
    templateQuery: "#wlan-client-details"
