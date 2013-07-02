
# Node.js require with fallback support

module.exports = (paths...) ->
  err = null
  while path = paths.shift()
    try
      if ob = require(path)
        console.info "Using", path
        return ob
    catch e
      err = e
  throw err
