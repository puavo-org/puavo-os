###*
# Read mac addresses of network devices
###

fs = require "fs"
path = require "path"

devicesPath = "/sys/class/net/"

devices = {}

for file in fs.readdirSync(devicesPath)
  continue if file is "lo"
  addressPath = path.join(devicesPath, file, "address")
  devices[file] =
    mac: fs.readFileSync(addressPath).toString().trim()

module.exports = devices

