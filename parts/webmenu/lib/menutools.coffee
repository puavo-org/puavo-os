
# Inject .desktop to menu structure

path = require "path"
dotdesktop = require "./dotdesktop"
fs = require "fs"

osIconPath = (iconSearchPaths, id, fallbackIcon) ->
  osIconFilePath = fallbackIcon
  iconSearchPaths.forEach (p) ->
    filePath = "#{ p }/#{ id }.png"
    if fs.existsSync( filePath )
      osIconFilePath = filePath

  return osIconFilePath

injectDesktopData = (menu, sources, locale, iconSearchPaths, fallbackIcon, hostType) ->

  sources.forEach (desktopDir) ->

    # Allow custom icons with relative path from Webmenu installation dir
    if menu.osIconPath and menu.osIconPath[0] isnt "/"
      menu.osIconPath = path.join(__dirname, "..", menu.osIconPath)

    # Operating system icon
    if menu.osIcon
      menu.osIconPath = osIconPath(iconSearchPaths, menu.osIcon, fallbackIcon)

    if menu.inactiveByDeviceType and menu.inactiveByDeviceType is hostType
      menu.status = "inactive"

    if menu.type is "desktop"
      if not menu.source
        throw new Error("'desktop' item in menu.json item is missing " +
          "'source' attribute: #{ JSON.stringify(menu) }")

      filePath = desktopDir + "/#{ menu.source }.desktop"
      try
        desktopEntry = dotdesktop.parseFileSync(filePath, locale)
      catch err
        return

      menu.id ?= menu.source
      menu.name ?= desktopEntry.name
      menu.description ?= desktopEntry.description
      menu.command ?= desktopEntry.command
      menu.osIconPath ?= osIconPath(iconSearchPaths, desktopEntry.osIcon, fallbackIcon)
      menu.upstreamName ?= desktopEntry.upstreamName

    else if menu.type is "menu"
      for menu_ in menu.items
        injectDesktopData(menu_, sources, locale, iconSearchPaths, fallbackIcon, hostType)


    if not menu.name
      console.error "Cannot find name for menu entry", menu
      console.error "Maybe just add it manually?"
      process.exit(1)

module.exports =
  injectDesktopData: injectDesktopData
