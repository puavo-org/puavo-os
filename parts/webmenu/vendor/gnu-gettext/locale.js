
var ffi = require("ffi");

// Temp patch for https://github.com/rbranson/node-ffi/issues/93
var libc = ffi.Library("/lib/i386-linux-gnu/libc.so.6", {
  "setlocale": [ "string", ["int", "string"] ]
});

module.exports = libc;

