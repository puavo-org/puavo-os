
fs = require "fs"


injectConfiguration = (config) ->
  if not fs.existsSync('/etc/puavo')
    console.log "WARN: Puavo configuration not found"
    return

  # Set puavoDomain if domain file found
  try
    if puavoDomain = fs.readFileSync("/etc/puavo/domain").toString()
      if config.passwordCMD?
        config.passwordCMD.url = "https://#{puavoDomain}/users/password/own"
  catch err
    console.log "WARN: ", "/etc/puavo/domain file not found"


module.exports =
  injectConfiguration: injectConfiguration
