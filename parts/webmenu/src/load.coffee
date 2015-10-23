
# node.js style require with yaml and fallback support
_ = require "underscore"
YAML = require "yamljs"
fs = require "fs"


load = (path, options) ->
    try
        if path.endsWith(".json")
            return JSON.parse(fs.readFileSync(path).toString())
        else if path.endsWith(".yaml")
            return YAML.parse(fs.readFileSync(path).toString())
        else
            return require(path)
    catch err
        if options.error isnt false
            throw err
        else
            return null



loadFallback = (paths...) ->
    paths = _.flatten(paths)
    err = null
    while path = paths.shift()
        try
            return load(path)
        catch e
            err = e
    throw err


module.exports = {
    load: load
    loadFallback: loadFallback
}
