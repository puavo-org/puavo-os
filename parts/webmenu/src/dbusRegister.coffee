Q = require "q"
domain = require "domain"

dbusRegister = ->
    if not process.env.DESKTOP_AUTOSTART_ID
        return Q("no need to register")

    # Creating the sessionBus seems to throw random EPIPE exceptions. Capture
    # them with domain and wrap them to promises
    defer = Q.defer()
    d = domain.create()
    d.on "error", defer.reject
    d.run ->
        dbus = require "dbus-native"
        sessionBus = dbus.sessionBus()
        service = sessionBus.getService("org.gnome.SessionManager")
        service.getInterface '/org/gnome/SessionManager',
            "org.gnome.SessionManager",
            (err, session) ->
                throw err if err

                session.on "ClientAdded", (client) ->
                    session.UnregisterClient(
                        process.env.DESKTOP_AUTOSTART_ID
                    )
                    defer.resolve("registration sent")

                session.RegisterClient(
                    "webmenu.desktop",
                    process.env.DESKTOP_AUTOSTART_ID
                )

    return defer.promise

module.exports = dbusRegister
