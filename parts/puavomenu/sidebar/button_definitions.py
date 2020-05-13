# Button definitions

from strings import STRINGS
import utils


SB_CHANGE_PASSWORD = {
    'name': 'change_password',

    'title': STRINGS['sb_change_password'],

    'icon': '/usr/share/icons/Faenza/emblems/96/emblem-readonly.png',

    'command': {
        'type': 'webwindow',
        'args': 'http://$(puavo_domain)/users/password/own?changing=$(user_name)&lang=$(user_language)&theme=$(user_theme)$(password_tabs)',
        'have_vars': True,
        'webwindow': {
            'title': STRINGS['sb_change_password_window_title'],
            'width': 1000,
            'height': 650,
            'enable_js': True,
        },
    },
}

SB_SUPPORT = {
    'name': 'support',

    'title': STRINGS['sb_support'],

    'icon': '/usr/share/icons/Faenza/status/96/dialog-question.png',

    'command': {
        'type': 'url',
        'args': utils.puavo_conf('puavo.support.new_bugreport_url',
                                 'https://tuki.opinsys.fi')
    },
}

SB_LAPTOP_SETTINGS = {
    'name': 'laptop-settings',

    'title': STRINGS['sb_laptop_setup'],

    'icon': '/usr/share/icons/Faenza/devices/96/drive-harddisk-system.png',

    'command': {
        'type': 'command',
        'args': 'puavo-laptop-setup',
    },
}

SB_PUAVOPKG_INSTALLER = {
    'name': 'puavopkg-installer',

    'title': STRINGS['sb_puavopkg_installer'],

    'icon': '/usr/share/icons/Faenza/apps/48/system-installer.png',

    'command': {
        'type': 'command',
        'args': 'puavo-pkgs-ui',
    },
}

SB_SYSTEM_SETTINGS = {
    'name': 'system-settings',

    'title': STRINGS['sb_system_settings'],

    'icon': '/usr/share/icons/Faenza/categories/96/applications-system.png',

    'command': {
        'type': 'command',
        'args': 'gnome-control-center',
    },
}

SB_LOCK_SCREEN = {
    'name': 'lock-screen',

    'title': STRINGS['sb_lock_screen'],

    'icon': '/usr/share/icons/Faenza/actions/96/system-lock-screen.png',

    'command': {
        'type': 'command',
        'args': [
            'dbus-send',
            '--type=method_call',
            '--dest=org.gnome.ScreenSaver',
            '/org/gnome/ScreenSaver',
            'org.gnome.ScreenSaver.Lock'
        ]
    },
}

SB_SLEEP_MODE = {
    'name': 'sleep-mode',

    'title': STRINGS['sb_hibernate'],

    'icon': '/usr/share/icons/oxygen/base/32x32/actions/system-suspend-hibernate.png',

    'command': {
        'type': 'command',
        'args': [
            'dbus-send',
            '--system',
            '--print-reply',
            '--dest=org.freedesktop.login1',
            '/org/freedesktop/login1',
            'org.freedesktop.login1.Manager.Suspend',
            'boolean:true'
        ]
    },
}

SB_LOGOUT = {
    'name': 'logout',

    'title': STRINGS['sb_logout'],

    'icon': '/usr/share/icons/gnome/32x32/actions/gnome-session-logout.png',

    'command': {
        'type': 'command',
        'args': 'gnome-session-quit --logout'
    },
}

SB_RESTART = {
    'name': 'restart',

    'title': STRINGS['sb_restart'],

    'icon': '/usr/share/icons/oxygen/base/32x32/actions/system-reboot.png',

    'command': {
        'type': 'command',
        'args': 'gnome-session-quit --reboot'
    }
}

SB_SHUTDOWN = {
    'name': 'shutdown',

    'title': STRINGS['sb_shutdown'],

    'icon': '/usr/share/icons/oxygen/base/32x32/actions/system-shutdown.png',

    'command': {
        'type': 'command',
        'args': 'gnome-session-quit --power-off'
    }
}
