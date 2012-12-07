
# http://askubuntu.com/a/201327/1241

# TODO: Use some real dbus library

{exec, spawn} = require "child_process"

call = (cmd) ->
  if Array.isArray(cmd)
    cmd = cmd.join " "

  process.stderr.write "Executing: '#{ cmd }'\n"
  child = exec cmd
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr


###*
# Manage computer power state
#
# @class powermanager
# @static
###
module.exports =

  ###*
  # Shutdown computer
  #
  # @method shutdown
  ###
  shutdown: -> call([
    'dbus-send'
    '--system'
    '--print-reply'
    '--dest="org.freedesktop.ConsoleKit"'
    '/org/freedesktop/ConsoleKit/Manager'
    'org.freedesktop.ConsoleKit.Manager.Stop'
  ])

  restart: -> call([
    'dbus-send'
    '--system'
    '--print-reply'
    '--dest="org.freedesktop.ConsoleKit"'
    '/org/freedesktop/ConsoleKit/Manager'
    'org.freedesktop.ConsoleKit.Manager.Restart'
  ])

  sleep: -> call([
    'dbus-send'
    '--system'
    '--print-reply'
    '--dest="org.freedesktop.UPower"'
    '/org/freedesktop/UPower'
    'org.freedesktop.UPower.Suspend'
  ])

  hibernate: -> call([
    'dbus-send'
    '--system'
    '--print-reply'
    '--dest="org.freedesktop.UPower"'
    '/org/freedesktop/UPower'
    'org.freedesktop.UPower.Hibernate'
  ])

  logout: -> call([
    'dbus-send'
    '--session'
    '--type=method_call'
    '--print-reply'
    '--dest=org.gnome.SessionManager'
    '/org/gnome/SessionManager'
    'org.gnome.SessionManager.Logout'
    'uint32:1'
  ])
