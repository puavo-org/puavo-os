
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


module.exports = (msg, cb) ->

  command = commandBuilders[msg.type]?(msg)

  if not command
    console.log "no commad for type #{ msg.type }"
    return

  [command, args] = command

  console.log "Executing '#{ command }'"

  cmd = spawn command, args,
    detached: true
    cwd: process.env.HOME

  cmd.on "exit", (code) ->
    console.log "Command '#{ command } #{ args.join " " } exited with #{ code }"
    cb?() # TODO: create an error object...


