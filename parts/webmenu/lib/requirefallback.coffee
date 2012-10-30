
# Node.js require with fallback support

module.exports = (paths...) ->
  err = null
  while path = paths.shift()
    try
      return require(path)
    catch e
      err = e
  throw err
