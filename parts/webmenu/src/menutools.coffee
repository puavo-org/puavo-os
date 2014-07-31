
# Inject .desktop to menu structure

path = require "path"
dotdesktop = require "./dotdesktop"
fs = require "fs"
execSync = require "execSync"

findOsIcon = (iconSearchPaths, id, fallbackIcon) ->
  try
    # Return if id is a real path
    r = fs.realpathSync(id)
    return r
  catch e
    # Otherwise just continue searching

  osIconFilePath = fallbackIcon

  iconSearchPaths.forEach (p) ->
    ["svg", "png", "jpg"].forEach (ext) ->
      filePath = "#{ p }/#{ id }.#{ ext }"
      if fs.existsSync(filePath)
        osIconFilePath = filePath

  return osIconFilePath


normalizeIconPath = (p) ->
  return p if not p

  # skip if already has a protocol
  if /^[a-z]+\:.+$/.test(p)
    return p

  if p[0] is"/"
    return "file://#{ p }"

  return "file://" + path.join(__dirname, "..", p)


injectDesktopData = (menu, desktopFileSearchPaths, locale, iconSearchPaths, fallbackIcon, hostType) ->

  if menu.type is "custom"
    # Can string or array
    command = [].concat(menu.command)[0]

    code = execSync.run("which #{ command }")
    if code isnt 0
        menu.broken = true
        console.warn("WARNING: Custom command broken: " + command)

  # Operating system icon
  if menu.osIcon
    menu.osIconPath = findOsIcon(iconSearchPaths, menu.osIcon, fallbackIcon)

  if menu.inactiveByDeviceType and menu.inactiveByDeviceType is hostType
    menu.status = "inactive"

  if menu.type is "desktop"
    if not menu.source
      throw new Error("'desktop' item in menu.json item is missing " +
        "'source' attribute: #{ JSON.stringify(menu) }")

    desktopFileSearchPaths.forEach (desktopDir) ->
      filePath = desktopDir + "/#{ menu.source }.desktop"
      try
        desktopEntry = dotdesktop.parseFileSync(filePath, locale)
      catch err
        return

      menu.id ?= menu.source
      menu.name ?= desktopEntry.name
      menu.description ?= desktopEntry.description
      menu.command ?= desktopEntry.command
      menu.osIconPath ?= findOsIcon(iconSearchPaths, desktopEntry.osIcon, fallbackIcon)
      menu.upstreamName ?= desktopEntry.upstreamName
      menu.osIconPath = normalizeIconPath(menu.osIconPath)

    if not menu.name
      console.error "WARNING: Cannot find name for .desktop entry: " + menu.source
      menu.broken = true

  if menu.type is "menu"
    for menu_ in menu.items
      injectDesktopData(menu_, desktopFileSearchPaths, locale, iconSearchPaths, fallbackIcon, hostType)

module.exports =
  injectDesktopData: injectDesktopData
