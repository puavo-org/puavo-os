
{spawn, fork} = require "child_process"

commandBuilders =
  desktop: (msg) ->
    if not msg.command
      console.error "Missing command from", msg
      return
    [command, args...] = msg.command
    return [command, args]

  custom: (msg) -> this.desktop(msg)

  web: (msg) ->
    args = [msg.url]
    return ["xdg-open", args]


launchCommand = (msg, cb) ->

  if Array.isArray(msg)
    return launchCommand({
      type: "custom"
      command: msg
    }, cb)

  console.info "Launching #{ JSON.stringify(msg) }"

  command = commandBuilders[msg.type]?(msg)

  if not command
    console.info "no commad for type #{ msg.type }"
    return

    cb?() # TODO: create an error object...

  command = command.map((p) -> '"' + p + '"').join(" ")

  console.info "Executing '#{ command }'"
  cmd = spawn "sh", ["-c", command + " &"],
    detached: true
    cwd: process.env.HOME
    env: process.env

  cmd.on "exit", (code) ->
    console.info "Command '#{ command }'exited with #{ code }"
    cb?() # TODO: create an error object...


module.exports  = launchCommand
