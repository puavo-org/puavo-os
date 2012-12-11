
var ffi = require("ffi");

var libc = ffi.Library("libc", {
  "setlocale": [ "string", ["int", "string"] ]
});

module.exports = libc;

