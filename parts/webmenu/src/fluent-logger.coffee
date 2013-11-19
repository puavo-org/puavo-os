_ = require "underscore"
pkg = require "../package.json"

if process.env.WM_FLUENTD_ACTIVE
  console.info "Activating fluentd logging"
  logger = require "fluent-logger"
  logger.configure "webmenu", {
     host: "127.0.0.1"
     port: 24224
  }

  logger.on "error", (err) ->
    console.warn "fluentd error: #{ err.message }"

  module.exports = emit: (record) ->
    record.meta ||= {}
    record.meta.version = pkg.version
    logger.emit(record)

else
  console.info "Fluetnd logging disabled"
  module.exports = emit: ->
