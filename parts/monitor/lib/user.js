var hostType = require("./hosttype");

var exec = require('child_process').exec;

/**
 * Determine which user is using this computer. Just assume someone is
 * physically using it if some tty is being used.
 *
 * @param {Function} callback
 *  @param {Error} callback.error Error object or null
 *  @param {String} callback.username Username or undefined in the case of
 *  error
 **/
function getXUser(cb) {
  if (hostType === "thinclient") {
    exec("ps -ef", function(err, stdout, stderr) {
      if (err) return cb(err);

      var processList = stdout.split("\n").filter( function(line) {
            return line.match(/LTSP_CLIENT/);
      });

      if (processList.length == 0) {
        return cb(null);
      }

      var matchUser = processList[0].match(/-l ([^ ]+)/);

      if (!matchUser) {
        return cb(null);
      }

      return cb(null, matchUser[1]);
    });
  } else {
    exec("who", function(err, stdout, stderr) {
      var match;
      if (err) return cb(err);

      if (match = stdout.match(/(\w+)\s+tty[0-9]{1}/)) {
        return cb(null, match[1]);
      }

      return cb(null);

    });
  }
}

module.exports = getXUser;

if (require.main === module) {
  getXUser(function(err, user) {
    console.log("user", user);
  });
}
