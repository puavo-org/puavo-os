
fs = require "fs"
gettext = require "../vendor/gnu-gettext"
ini = require "ini"


# Call a function with given array of arguments arrays in series. Return on
# first truthty return value.
callUntilOk = (fn, argList...) ->
  return if argList.length is 0
  if res = fn argList.shift()...
    return res
  else
    return callUntilOk(fn, argList...)


# Parse system locale, eg. fi_FI.UTF-8 to object
parseLocale = (systemLocale) ->
  ob = {}
  [locale, encoding] =  systemLocale.split(".")
  ob.l
  ob.locale = locale
  ob.encoding = encoding if encoding
  ob.lang = locale.split("_")[0]
  ob.original = systemLocale
  return ob


# Find translated version of an attribute from desktopEntry object
findTranslated = (desktopEntry, attr, systemLocale) ->
  original = desktopEntry[attr]

  if not systemLocale
    return original

  {lang, locale} = parseLocale(systemLocale)
  embedded = callUntilOk(_findEmbedded,
    [desktopEntry, attr, locale],
    [desktopEntry, attr, lang],
  )

  if embedded and embedded isnt original
    return embedded

  if domain = desktopEntry["X-Ubuntu-Gettext-Domain"]

    gettext.setLocale("LC_ALL", systemLocale)
    translated = gettext.dgettext(domain, original)
    if translated isnt original
      return translated


_findEmbedded = (desktopEntry, attr, lang) ->
  attr += "[#{ lang }]"
  return desktopEntry[attr]

findCommand = (desktopEntry) ->
  rawCmd = desktopEntry["Exec"]
  if not rawCmd
    err = new Error "Exec is missing for #{ desktopEntry["Name"] }"
    err.desktopEntry = desktopEntry
    throw err
  return rawCmd


parseFileSync = (filePath, locale) ->
  data = ini.parse fs.readFileSync(filePath).toString()
  desktopEntry = data["Desktop Entry"]

  if not desktopEntry
    throw new Error "Desktop Entry is missing for " + filePath

  return {
    lang: parseLocale(locale).lang
    name: callUntilOk(findTranslated,
      [desktopEntry, "GenericName", locale],
      [desktopEntry, "X-GNOME-FullName", locale],
      [desktopEntry, "Name", locale],
      [desktopEntry, "GenericName"],
      [desktopEntry, "Name"],
    )
    upstreamName: desktopEntry["Name"],
    description: callUntilOk(findTranslated,
      [desktopEntry, "Comment", locale],
      [desktopEntry, "Comment"],
    )
    command: findCommand(desktopEntry)
    osIcon: desktopEntry["Icon"]
  }

module.exports =
  parseLocale: parseLocale
  parseFileSync: parseFileSync

if require.main is module
  parse "/usr/share/applications/thunderbird.desktop"
