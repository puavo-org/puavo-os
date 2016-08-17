fs = require "fs"
path = require "path"
{exec} = require "child_process"

_ = require "underscore"

# Use local MessageFormat installation
messageformatCmd = path.join(process.cwd(), "node_modules/.bin/messageformat")

langRoot = "./i18n"

# Use english as base language for everything
masterLang = "en"

# Read master language
masterJSON = {}

fs.readdirSync(path.join(langRoot, masterLang))
    .filter (name) ->
        _.last(name.split(".")) is "json"
    .forEach (name) ->
        s = fs.readFileSync(path.join(langRoot, masterLang, name)).toString()
        masterJSON[name] = JSON.parse(s)

isUntranslated = (string) ->
    return true if not string
    return !! string.match /\[UNTRANSLATED\]$/

i18nUpdate = ->

    # Go throug all other languages
    fs.readdirSync(langRoot).filter (language) ->
        language isnt masterLang
    .forEach (language) ->

        for name, master of masterJSON
            currentFile = path.join(langRoot, language, name)

            # Read exsting translation file or create new empty one if missing
            try
                current = JSON.parse(
                    fs.readFileSync(currentFile).toString()
                )
            catch err
                current = {}

            # Copy translation keys from master to target if target does not already
            # have it
            for key, translation of master when isUntranslated(current[key])
                console.log "Adding '#{ key }: #{ master[key] }' to #{ language }/#{ name }"
                current[key] = master[key]
                # Add [UNTRANSLATED] tag to warn about missing translations
                current[key] += " [UNTRANSLATED]"

            # Go through existing translations
            for key, translation of current
                # Delete the translation if it has been removed from the master
                if not master[key]
                    console.log(
                        "Deleting '#{ key }: #{ translation }' from "
                        "#{ language }/#{ name } because it has been removed from the "
                        "master language (#{ masterLang })"
                    )
                    delete current[key]
                # Warn if untranslated tag is still present
                else if isUntranslated(translation)
                    console.log "Untranslated '#{ key }: #{ translation }' in #{ language }/#{ name }"

            # Write translation json back to file system
            fs.writeFileSync(currentFile, JSON.stringify(current, null, "  "))


    # Compile translations to raw Javascript code for speed
    fs.readdirSync(langRoot).forEach (language) ->
        langDir = path.join(langRoot, language)
        exec "#{ messageformatCmd } --namespace window.MF --locale #{ language }",
            cwd: langDir
        , (err, stdout, stderr) ->
            throw err if err

module.exports = i18nUpdate

if require.main is module
  i18nUpdate()
