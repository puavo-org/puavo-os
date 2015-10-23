
# node.js style require with yaml and fallback support
_ = require "underscore"
YAML = require "yamljs"
fs = require "fs"
{join} = require "path"


load = (path) ->
    if path.endsWith(".json")
        return JSON.parse(fs.readFileSync(path).toString())
    else if path.endsWith(".yaml")
        return YAML.parse(fs.readFileSync(path).toString())

    throw new Error "Unknown file type: #{ path }"

# Get array of paths for files in given directories
readDirectoryD = (dirs...) ->
    dirs = _.flatten(dirs)
    paths = []

    for dir in dirs
        files = null
        try
            files = fs.readdirSync(dir)
        catch err
            throw err if err.code isnt "ENOENT"
            continue

        if files
            for name in files when name[0] isnt "."
                paths.push(join(dir, name))

    return paths


loadFallback = (paths...) ->
    paths = _.flatten(paths)
    while path = paths.shift()
        try
            return load(path)
        catch err
            console.log "Cannot load file: #{ path }"
            console.log "Error: #{ err.message }"


module.exports = {
    load: load
    readDirectoryD: readDirectoryD
    loadFallback: loadFallback
}
