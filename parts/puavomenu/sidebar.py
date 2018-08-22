# Sidebar buttons, icons and commands


SIDEBAR_SEPARATOR = {'type': 'separator'}


SIDEBAR_BUTTONS = [
    {
        'name': 'change-password',

        'title': {
            'en': 'Change password',
            'fi': 'Vaihda salasana',
            'sv': 'Byt lösenord',
            'de': 'Passwort ändern',
        },

        'description': {
            'fi': 'Vaihda salasana',
            'en': 'Change password',
            'sv': 'Byt lösenord',
            'de': 'Passwort ändern',
        },

        'icon': '/usr/share/icons/Faenza/emblems/96/emblem-readonly.png',

        'command': {
            'type': 'webwindow',
            'args': 'https://$(puavo_domain)/users/password/own?changing=$(user_name)',
            'have_vars': True,
        },

        'disabled_for_guests': True,
    },

    {
        'name': 'support',

        'title': {
            'en': 'Support',
            'fi': 'Tukisivusto',
            'sv': 'Support',
            'de': 'Support',
        },

        'icon': '/usr/share/icons/Faenza/status/96/dialog-question.png',

        'command': {
            'type': 'url',
            'args': 'https://tuki.opinsys.fi'
        },
    },

    {
        'name': 'system-settings',

        'title': {
            'en': 'System settings',
            'fi': 'Järjestelmän asetukset',
            'sv': 'Systeminställningar',
            'de': 'Systemeinstellungen',
        },

        'icon': '/usr/share/icons/Faenza/categories/96/applications-system.png',

        'command': {
            'type': 'command',
            'args': 'gnome-control-center',
        },
    },

    SIDEBAR_SEPARATOR,

    {
        'name': 'lock-screen',

        'title': {
            'en': 'Lock screen',
            'fi': 'Lukitse näyttö',
            'sv': 'Lås skärmen',
            'de': 'Bildschirm sperren'
        },

        'icon': '/usr/share/icons/Faenza/actions/96/system-lock-screen.png',

        'command': {
            'type': 'command',
            'args': ['dbus-send',
                     '--type=method_call',
                     '--dest=org.gnome.ScreenSaver',
                     '/org/gnome/ScreenSaver',
                     'org.gnome.ScreenSaver.Lock']
        },

        'disabled_for_guests': True,
    },

    {
        'name': 'sleep-mode',

        'title': {
            'en': 'Sleep',
            'fi': 'Unitila',
            'sv': 'Strömsparläge',
            'de': 'Schlafen'
        },

        'icon': '/usr/share/icons/oxygen/base/32x32/actions/system-suspend-hibernate.png',

        'command': {
            'type': 'command',
            'args': ['dbus-send',
                     '--system',
                     '--print-reply',
                     '--dest=org.freedesktop.login1',
                     '/org/freedesktop/login1',
                     'org.freedesktop.login1.Manager.Suspend',
                     'boolean:true']
        },
    },

    {
        'name': 'logout',

        'title': {
            'en': 'Logout',
            'fi': 'Kirjaudu ulos',
            'sv': 'Logga ut',
            'de': 'Abmelden'
        },

        'icon': '/usr/share/icons/gnome/32x32/actions/gnome-session-logout.png',

        'command': {
            'type': 'command',
            'args': 'gnome-session-quit --logout'
        },
    },

    SIDEBAR_SEPARATOR,

    {
        'name': 'restart',

        'title': {
            'en': 'Restart',
            'fi': 'Käynnistä uudelleen',
            'sv': 'Starta om',
            'de': 'Neustarten'
        },

        'icon': '/usr/share/icons/oxygen/base/32x32/actions/system-reboot.png',

        'command': {
            'type': 'command',
            'args': 'gnome-session-quit --reboot'
        }
    },

    {
        'name': 'shutdown',

        'title': {
            'en': 'Shut down',
            'fi': 'Sammuta',
            'sv': 'Stäng av',
            'de': 'Herunterfahren',
        },

        'icon': '/usr/share/icons/oxygen/base/32x32/actions/system-shutdown.png',

        'command': {
            'type': 'command',
            'args': 'gnome-session-quit --power-off'
        }
    },
]
