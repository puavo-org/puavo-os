
fs = require("fs")

logger = require "./fluent-logger"
startedFile = process.env.WM_HOME + "/started"

started = null

try
    started = fs.readFileSync(startedFile).toString()
    fs.unlinkSync(startedFile)
catch err
    # ok to be missing on restarts and development

logStartTime = (msg) ->
    return if not started

    sinceStart = (Date.now()/1000) - parseInt(started, 10)

    console.log(msg.trim() + "  in " + sinceStart + " seconds")
    logger.emit(
      msg: msg
      time: sinceStart
    )

module.exports = logStartTime
