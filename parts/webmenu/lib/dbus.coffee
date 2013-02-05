dbus = require 'dbus-native'
sessionBus = dbus.sessionBus()

registerApplication = () ->
  if process.env.DESKTOP_AUTOSTART_ID
    service = sessionBus.getService("org.gnome.SessionManager")
    service.getInterface '/org/gnome/SessionManager',
      "org.gnome.SessionManager",
      (err, session) ->
        throw err if err
      
        session.on "ClientAdded", (client) ->
          session.UnregisterClient process.env.DESKTOP_AUTOSTART_ID
      
        session.RegisterClient "webmenu.desktop", process.env.DESKTOP_AUTOSTART_ID
    

module.exports =
  registerApplication: registerApplication
