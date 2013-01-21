
var fs = require("fs");

/**
 * Allow only one instance of this node process. Exit with status code 1 if
 * process with pid file exists.
 *
 * @param {String} pidFile Path to a pid file
 **/
module.exports = function(pidFile) {

  try {
    var pid = fs.readFileSync(pidFile).toString().trim();
  }
  catch (err) {
    if (err.code !== "ENOENT") throw err;
  }

  if (pid) {
    try {
      var stat = fs.statSync("/proc/" + pid);
      console.error("Already running in pid " + pid);
      process.exit(1);
    }
    catch (err) {
      if (err.code !== "ENOENT") throw err;
    }
  }

  fs.writeFileSync(pidFile, process.pid.toString());
};

