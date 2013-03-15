define [
  "handlebars"
], (
  Handlebars
) ->

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
  i18n = (key, data) ->
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

  Handlebars.registerHelper "i18n", i18n
  return i18n
