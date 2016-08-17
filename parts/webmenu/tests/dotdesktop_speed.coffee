
fs = require "fs"
dotdesktop = require "../lib/dotdesktop"

files = fs.readdirSync "/usr/share/applications/"

start = Date.now()
count = 0

for file in files

  if not file.match /\.desktop$/
    continue

  file = "/usr/share/applications/" + file
  console.log "\nParsing", file
  try
    console.log dotdesktop.parseFileSync file, "fi_FI.UTF-8"
    count += 1
  catch e
    console.error "Failed to parse", file


diff = (Date.now() - start) / 1000

console.log "\nRead #{ count } .desktop files in #{ diff } seconds"
console.log (count / diff), "files/sec"
