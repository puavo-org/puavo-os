
fs = require "fs"

readFirst = (paths, cb) ->
  [head, rest...] = paths
  if not head
    return cb new Error "failed to read file"

  fs.readFile head, (err, data) ->
    if err
      return readFirst(rest, cb)
    else
      console.log "read file from #{ head }"
      cb null, data


module.exports = (searchPaths, fallback) -> (req, res) ->

  filePaths = searchPaths.map (p) ->
    "#{ p }/#{ req.params.icon }.png"
  filePaths.push(fallback)

  readFirst filePaths, (err, data) ->
    if err
      res.send 404, "fail"
      console.error "Failed to read image from", searchPaths
    else
      res.setHeader "Content-type", "image/png"
      res.send data


