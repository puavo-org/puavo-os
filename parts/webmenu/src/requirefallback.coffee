
# Node.js require with fallback support
_ = require "underscore"
YAML = require "yamljs"
fs = require "fs"

module.exports = (paths...) ->
  paths = _.flatten(paths)
  err = null
  while path = paths.shift()
    try
      if path.endsWith(".json")
        return JSON.parse(fs.readFileSync(path).toString())
      else if path.endsWith(".yaml")
        return YAML.parse(fs.readFileSync(path).toString())
      else
        return require(path)
    catch e
      err = e
  throw err
