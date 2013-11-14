
var fs = require("fs");

var startedFile = process.env.WM_HOME + "/started";

function logStartTime(msg) {
    fs.readFile(startedFile, function(err, data) {
        if (err) return;
        started = parseInt(data.toString(), 10);
        var sinceStart = (Date.now()/1000) - started;
        console.log(msg.trim() + "  in " + sinceStart + " seconds");
        fs.unlink(startedFile, function(err) {
            if (err) {
                console.error("Failed to unlink startup file", err);
            }
        });
    });
}

module.exports = logStartTime;
