/**
 * kernel arch detection routines.
 * @exports {String} kernelArch
 **/

var sh = require("execSync");
var kernelArch;

var result = sh.exec('uname -m');

if (result.code !== 0) {
  throw('uname -m failed');
}

kernelArch = result.stdout.trim();

module.exports = kernelArch;
