
if process.env.WM_FLUENTD_ACTIVE
  logger = require "fluent-logger"
  logger.configure "webmenu", {
     host: "127.0.0.1"
     port: 24224
  }

  logger.on "error", (err) ->
    console.warn "fluentd error: #{ err.message }"

  module.exports = logger

else
  module.exports = emit: ->
