
# Node.js require with fallback support
_ = require "underscore"

module.exports = (paths...) ->
  paths = _.flatten(paths)
  err = null
  while path = paths.shift()
    try
      if ob = require(path)
        console.info "Using", path
        return ob
    catch e
      err = e
  throw err
