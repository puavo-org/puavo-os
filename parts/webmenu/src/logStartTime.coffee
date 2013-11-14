
fs = require("fs")

logger = require "./fluent-logger"
startedFile = process.env.WM_HOME + "/started"

logStartTime = (msg) ->
    fs.readFile startedFile, (err, data) ->
        return if err # ok to be removed after restarts

        started = parseInt(data.toString(), 10)
        sinceStart = (Date.now()/1000) - started

        console.log(msg.trim() + "  in " + sinceStart + " seconds")
        logger.emit(
          msg: msg
          time: sinceStart
        )

        fs.unlink startedFile, (err) ->
            if err
                console.error("Failed to unlink startup file", err)


module.exports = logStartTime;
