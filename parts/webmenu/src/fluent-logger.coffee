_ = require "underscore"
pkg = require "../package.json"
fs = require "fs"

GIT_COMMIT = fs.readFileSync("GIT_COMMIT").toString().trim()

if process.env.WM_FLUENTD_ACTIVE
  console.info "Activating fluentd logging"
  logger = require "fluent-logger"
  logger.configure "webmenu", {
     host: "127.0.0.1"
     port: 24224
  }

  logger.on "error", (err) ->
    console.warn "fluentd error: #{ err.message }"

  module.exports =
    emit: (label, record) ->
      if typeof label isnt "string"
        record = label
        label = ""

      record.meta ?= {}
      record.meta.version = "#{ pkg.version } #{ GIT_COMMIT }"
      logger.emit(label, record)
    active: true

else
  console.info "Fluentd logging disabled"
  module.exports = emit: ->
