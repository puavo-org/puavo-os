/*jshint boss:true, node:true */


var ffi = require("ffi");


// Working around https://github.com/rbranson/node-ffi/issues/93

var libc;
var err;

var libcPaths = [
  "/lib/i386-linux-gnu/libc.so.6",
  "/lib/x86_64-linux-gnu/libc.so.6",
  "libc"
];

for (var i = 0; i < libcPaths.length; i += 1) {
  var path = libcPaths[i];
  err = null;
  try {

    libc = ffi.Library(path, {
      "setlocale": [ "string", ["int", "string"] ]
    });
    break;

  } catch (e) {
    err = e;
  }
}

if (err) throw err;
module.exports = libc;

