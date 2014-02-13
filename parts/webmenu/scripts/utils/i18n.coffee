Handlebars = require "hbsfy/runtime"

if not window.MF
    throw new Error "i18n.js is not loaded!"

untranslatedRegexp = /\s{1}\[UNTRANSLATED\]$/

###*
# Wrap i18n object from messageformat.js. Make sure it does not crash if a
# translation key is missing during runtime.
# https://github.com/SlexAxton/messageformat.js
#
# @param {String} key Translation key
# @param {Object} data Translation data
###
translate = (key, data) ->
    current = window.MF
    for attr in key.split(".")
        current = current[attr]
    if typeof current isnt "function"
        console.error "Translation key is missing: #{ key }"
        return "[#{ key }]"

    translation = current(data)
    if translation.match(untranslatedRegexp)
        clean = translation.replace(untranslatedRegexp, "")
        console.error "#{ window.navigator.language }: Translation missing #{ key }: #{ clean }"
        return clean

    return translation


###*
# Pick translated string from an object. This is used for translated menu
# content where strings can be defined also as a translation object. If
# requested language is missing it fallbacks to english.
#
# Example:
#
#  {
#    "en": "Calculator",
#    "fi": "Laskin"
#  }
#
###
pick = (ob) ->
    # No need to translate falsy values
    return "" if not ob

    # Just return the string if we have no translation object.
    return ob if typeof ob is "string"

    if s = ob[window.LANG]
        return s
    else
        console.warn "Content translation missing for #{ window.LANG } in #{ JSON.stringify(ob) }"
        return ob.en or ob.fi or ob.se # Fallback to other languages prefering english

translate.pick = pick
Handlebars.registerHelper "i18n", translate
Handlebars.registerHelper "i18nPick", pick

module.exports = translate
