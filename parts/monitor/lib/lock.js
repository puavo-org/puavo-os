

var fs = require("fs");
var fse = require("fs-ext");

module.exports = function(lockFile, cb) {

  fs.open(lockFile, "w", function(err, fd) {
    if (err) return cb(err);

    var timer = setTimeout(function() {
      var err = new Error("flock timeout");
      err.code = "FLOCK_TIMEOUT";
      cb(err);
      cb = function() {}; // Disable callback for flock
    }, 300);

    fse.flock(fd, "ex", function(err) {
      clearTimeout(timer);
      return cb(err);
    });

  });

};
