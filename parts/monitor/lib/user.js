
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
  exec("who", function(err, stdout, stderr) {
    var match;
    if (err) return cb(err);

    if (match = stdout.match(/(\w+)\s+tty[0-9]{1}/)) {
      return cb(null, match[1]);
    }

    return cb(null);

  });
}

module.exports = getXUser;

if (require.main === module) {
  getXUser(function(err, user) {
    console.log("user", user);
  });
}
