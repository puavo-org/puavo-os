
{spawn, fork} = require "child_process"
parseExec = require("./parseExec")

commandBuilders =
  desktop: (msg) ->
    if not msg.command
      console.error "Missing command from", msg
      return

    if typeof msg.command == "string"
      [command, args...] = parseExec(msg.command)
    else
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

  [command, args] = commandBuilders[msg.type]?(msg)

  if not command
    console.info "no commad for type #{ msg.type }"
    return cb?(new Error("CMD object has no command!"))


  # Build shell executable string. Quote everything to make args and commands
  # with spaces to work correctly.
  command = '"' + command + '" ' + args.map((p) -> '"' + p + '"').join(" ")

  console.info "Executing '#{ command }'"

  # Manually fokr command because detached option is broken in node-webkit 0.6
  cmd = spawn "sh", ["-c", command + " &"],
    detached: true
    cwd: process.env.HOME
    env: process.env

  cmd.on "exit", (code) ->
    console.info "Command '#{ command }'exited with #{ code }"
    cb?() # TODO: create an error object...


module.exports  = launchCommand
