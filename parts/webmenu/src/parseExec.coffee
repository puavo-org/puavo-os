
_ = require "underscore"
s = require "underscore.string"

# Parse free desktop Exec field to an array
# http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#exec-variables
parseExec = (cmdStr) ->

  cmdStr = cmdStr.trim()

  cmd = null
  # Find command from Exec string. Paths with spaces are surrounded with quotes.
  for matcher in [ /^'(.+)'(.*)/, /^"(.+)"(.*)/, /^([^ ]+)(.*)/ ]
    if match = cmdStr.match(matcher)
      [__, cmd, args] = match
      break

  if not cmd
    console.error "failed to parse #{ cmdStr }"
    throw new Error "Failed to parse cmd: '#{ cmdStr }'"

  # Remove Exec variables for now.
  # http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#exec-variables
  args = args.replace(/%[fFuUdDnNickvm]{1}/g, "")
  args = _.compact(s.clean(args).split(" "))
  return [cmd].concat(args)

module.exports = parseExec
