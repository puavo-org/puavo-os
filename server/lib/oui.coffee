

# http://standards.ieee.org/develop/regauth/oui/public.html
# http://standards.ieee.org/develop/regauth/oui/oui.txt

fs = require "fs"

macStart = /^([A-Fa-f0-9]{2}\-[A-Fa-f0-9]{2}\-[A-Fa-f0-9]{2}) +\(hex\)(.*)$/

macAddressMap = {}

data = fs.readFileSync __dirname + "/oui.txt"

for line in data.toString().split("\n")
  if m = line.match macStart
    macAddressMap[m[1]] = m[2].trim()


module.exports =
  lookup: (mac) ->
    vendorPrefix = mac.slice(0,8).replace(/:/g, "-").toUpperCase()
    return macAddressMap[vendorPrefix]


if require.main is module
  console.info module.exports.lookup "00:25:22:80:f6:e5"
