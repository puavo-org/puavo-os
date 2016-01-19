/**
 * host type detection rutines.
 * @exports {String} hostType
 **/

var fs = require("fs");

var hostType = [
  "/etc/puavo/hosttype", // New systems Quantal and next
  "/etc/opinsys/host/type" // Legacy lucid
].reduce(function(prev, filePath) {
  if (prev) return prev;
  try {
    return fs.readFileSync(filePath).toString().trim();
  } catch (err) {
    if (err.code !== "ENOENT") throw err;
  }

}, null);

// If hostType is fatclient check for lucid system bug
var ltsconf;
if (hostType === "fatclient") {
  try {
    ltsconf = fs.readFileSync("/var/cache/getltscfg-cluster/lts.conf").toString();
  }
  catch (err) {
    if (err.code !== "ENOENT") throw err;
  }
  if (ltsconf && ltsconf.match(/LTSP_FATCLIENT *= *False/)) {
    console.log("Lucid bug detected. hostType is thinclient");
    hostType = "thinclient";
  }
}

// Wild installations are just unregistered
if (!hostType) hostType = "unregistered";

module.exports = hostType;
