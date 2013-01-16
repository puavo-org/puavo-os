
http = require "http"

s = http.createServer (req, res) ->
  console.log req.method, req.url
  req.on "data", (data) ->
    console.log "req data", data.toString()
  res.end("foo")

s.listen 8080
