
dgram = require "dgram"

###*
# Callback for window.onerror
# https://developer.mozilla.org/en/docs/DOM/window.onerror
#
# Send Javascript errors to puavo-logrelay
#
# @param {String} errorMsg
# @param {String} url
# @param {Number} lineNumber
###
module.exports = (errorMsg, url, lineNumber) ->
  packet = {
    type: "webmenu"
    event: "jserror"
    date: Date.now()
    message: errorMsg
    url: url
    lineNumber: lineNumber
  }

  message = new Buffer(JSON.stringify packet)
  client = dgram.createSocket("udp4")
  client.on "error", (err) -> # prevent from throwing errors ever.
  client.send message, 0, message.length, 3858, "eventlog", (err) ->
    if err
      console.error "Failed to post js error to 'eventlog': #{ err.message }"


