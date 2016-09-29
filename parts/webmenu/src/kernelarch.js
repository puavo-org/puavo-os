/**
 * kernel arch detection routines.
 * @exports {String} kernelArch
 **/

var exec = require("sync-exec");
var kernelArch;

var result = exec('uname -m');

if (result.status !== 0) {
  throw('uname -m failed');
}

kernelArch = result.stdout.trim();

module.exports = kernelArch;
