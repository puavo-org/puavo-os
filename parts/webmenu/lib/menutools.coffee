
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

injectDesktopData = (menu, sources, locale, iconSearchPaths, fallbackIcon) ->
  if menu.type is "menu" &&  menu.osIcon
     menu.osIconPath = osIconPath(iconSearchPaths, menu.osIcon, fallbackIcon)

  sources.forEach (desktopDir) ->

    if menu.type is "desktop" and menu.id
      filePath = desktopDir + "/#{ menu.id }.desktop"
      try
        desktopEntry = dotdesktop.parseFileSync(filePath, locale)
      catch err
        console.log "Failed to parse #{ filePath }", err
        return

      menu.name ?= desktopEntry.name
      menu.description ?= desktopEntry.description
      menu.command ?= desktopEntry.command
      menu.osIconPath ?= osIconPath(iconSearchPaths, desktopEntry.osIcon, fallbackIcon)
      menu.upstreamName ?= desktopEntry.upstreamName

    else if menu.type is "menu"
      for menu_ in menu.items
        injectDesktopData(menu_, sources, locale, iconSearchPaths, fallbackIcon)


    if not menu.name
      console.error "Cannot find name for menu entry", menu
      console.error "Maybe just add it manually?"
      process.exit(1)

module.exports =
  injectDesktopData: injectDesktopData
