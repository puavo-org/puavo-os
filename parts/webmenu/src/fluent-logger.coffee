
if process.env.WM_FLUENTD_ACTIVE
  logger = require "fluent-logger"
  logger.configure "webmenu", {
     host: "127.0.0.1"
     port: 24224
  }
  module.exports = logger
else
  module.exports = emit: ->
