
# Inject .desktop to menu structure

path = require "path"
dotdesktop = require "./dotdesktop"

injectDesktopData = (menu, sources, locale, verbose) ->
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
      menu.osIcon ?= desktopEntry.osIcon
      menu.upstreamName ?= desktopEntry.upstreamName


    else if menu.type is "menu"
      for menu_ in menu.items
        injectDesktopData(menu_, sources, locale)

    if not menu.name
      console.error "Cannot find name for menu entry", menu
      console.error "Maybe just add it manually?"
      process.exit(1)

module.exports =
  injectDesktopData: injectDesktopData
