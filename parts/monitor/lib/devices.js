/**
* Read mac addresses of network devices
*/

var fs = require("fs");
var path = require("path");

var devicesPath = "/sys/class/net/";
var devices = {};

var deviceNames = fs.readdirSync(devicesPath);

var i, file;
for (i = 0; i < deviceNames.length; i += 1) {
  file = deviceNames[i];
  if (file === "lo") continue; // Skip loop device
  addressPath = path.join(devicesPath, file, "address");
  devices[file] = fs.readFileSync(addressPath).toString().trim();
}

module.exports = devices;

if (require.main === module) {
  console.log(devices);
}
