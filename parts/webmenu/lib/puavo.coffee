
fs = require "fs"


injectConfiguration = (config) ->
  if not fs.existsSync('/etc/puavo')
    console.log "WARN: Puavo configuration not found"
    return

  # Set puavoDomain if domain file found
  try
    if puavoDomain = fs.readFileSync("/etc/puavo/domain").toString().trim()
      if config.passwordCMD?
        config.passwordCMD.url = "https://#{puavoDomain}/users/password/own"
  catch err
    console.log "WARN: ", "/etc/puavo/domain file not found"


  try
    if hostType = fs.readFileSync("/etc/puavo/hosttype").toString().trim()
      config.hostType = hostType
  catch err
    console.log "WARN: ", "/etc/puavo/hosttype file not found"


module.exports =
  injectConfiguration: injectConfiguration
