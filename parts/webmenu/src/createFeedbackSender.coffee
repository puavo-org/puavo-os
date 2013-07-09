
Q = require "q"
{exec} = require "child_process"

module.exports = (cmd) -> (feedback) ->
  d = Q.defer()
  console.log "exec #{ cmd }"
  child = exec cmd, d.makeNodeResolver()
  child.stdin.on "error", (err) ->
  child.stdin.end(JSON.stringify(feedback) + "\n")
  d.promise
