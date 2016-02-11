
# Inject .desktop to menu structure

path = require "path"
stringify = require "json-stable-stringify"
fs = require "fs"
execSync = require "execSync"
crypto = require "crypto"
vm = require "vm"

_ = require "underscore"

dotdesktop = require "./dotdesktop"
parseExec = require "./parseExec"

# Generate unique hash from any json serializable object
json2hash = (ob) ->
  if ob and ob.type is "desktop" and ob.source
    return ob.source
  if typeof ob is "string"
    str = ob
  else
    str = stringify(ob)
  shasum = crypto.createHash("sha1")
  shasum.update(str)
  return shasum.digest("hex")


findOsIcon = (id, options) ->

  try
    # Return if id is a real path
    r = fs.realpathSync(id)
    return r
  catch e
    # Otherwise just continue searching

  osIconFilePath = options.fallbackIcon

  options.iconSearchPaths.forEach (p) ->
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


isValidMenuLauncher = (o) -> o.name && o.command

isConditionOk = (item) ->
  if typeof item.condition isnt "string"
    return true

  # Use JSON to ensure copies and only data. The condition code cannot be
  # trusted
  context = {
    env: JSON.parse(JSON.stringify(process.env))
    item: JSON.parse(JSON.stringify(item))
  }

  try
    # https://nodejs.org/docs/latest-v0.10.x/api/vm.html#vm_vm_runinnewcontext_code_sandbox_filename
    return !!vm.runInNewContext(item.condition, context)
  catch error
    console.error "Invalid item.condition #{ item.condition }", item, error
    return false


injectDesktopData = (menu, options) ->

  if menu.type is "custom"

    if Array.isArray(menu.command)
      command = menu.command
    else if typeof menu.command is "string"
      command = parseExec(menu.command)
    else
      throw new Error("Bad command in: #{ JSON.stringify(menu) }")


    code = execSync.run("which '#{ command[0] }' > /dev/null 2>&1")
    if code isnt 0
      if menu.installer
        menu.useInstaller = true
        menu.command = menu.installer
        menu.osIconPath = findOsIcon(options.installerIcon, options)
      else
        menu.hidden = true
        console.warn("WARNING: Custom command broken: " + command)
        return


  # Operating system icon
  if menu.osIcon
    menu.osIconPath = findOsIcon(menu.osIcon, options)

  if menu.inactiveByDeviceType and menu.inactiveByDeviceType is options.hostType
    menu.status = "inactive"

  if menu.onlyForArch and menu.onlyForArch isnt options.kernelArch
    menu.status = "inactive"

  if menu.type is "desktop"
    if not menu.source
      throw new Error("'desktop' item in menu.json item is missing " +
        "'source' attribute: #{ JSON.stringify(menu) }")


    desktopEntry = {}

    for desktopDir in options.desktopFileSearchPaths
      filePath = desktopDir + "/#{ menu.source }.desktop"
      try
        desktopEntry = dotdesktop.parseFileSync(filePath, options.locale)
        break
      catch err
        throw err if err.code isnt "ENOENT"

    # Override system .desktop file entries with Webmenu specific exceptions
    _.extend(desktopEntry, options.desktopItems[menu.source])

    # Use the desktop entry data as the default. Anything in menu.json will
    # override those
    _.defaults(menu, desktopEntry)

    menu.osIconPath ?= findOsIcon(menu.osIcon, options)
    menu.osIconPath = normalizeIconPath(menu.osIconPath)


    if not isValidMenuLauncher(menu) and menu.installer
      menu.useInstaller = true
      menu.command = menu.installer
      menu.osIconPath = findOsIcon(options.installerIcon, options)
      menu.name ?= menu.source

    if not isValidMenuLauncher(menu)
      console.error "WARNING: Cannot make proper .desktop entry: " + menu.source
      menu.hidden = true


  if not menu.hidden
    menu.hidden = not isConditionOk(menu)

  if menu.type is "menu"
    menu.id = json2hash(menu.name)
    for menu_ in menu.items
      injectDesktopData(menu_, options)
  else
    menu.id = json2hash(menu)

module.exports =
  injectDesktopData: injectDesktopData
