Q = require "q"
domain = require "domain"

dbusRegister = ->
    # Creating the sessionBus seems to throw random EPIPE exceptions. Capture
    # them with domain and wrap them to promises
    defer = Q.defer()
    d = domain.create()
    d.on "error", defer.reject
    d.run ->
        dbus = require "dbus-native"
        sessionBus = dbus.sessionBus()
        if process.env.DESKTOP_AUTOSTART_ID
            service = sessionBus.getService("org.gnome.SessionManager")
            service.getInterface '/org/gnome/SessionManager',
                "org.gnome.SessionManager",
                (err, session) ->
                    throw err if err

                    session.on "ClientAdded", (client) ->
                        session.UnregisterClient(
                            process.env.DESKTOP_AUTOSTART_ID
                        )
                        defer.resolve()

                    session.RegisterClient(
                        "webmenu.desktop",
                        process.env.DESKTOP_AUTOSTART_ID
                    )

    return defer.promise

module.exports = dbusRegister
