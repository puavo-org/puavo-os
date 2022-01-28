# Button definitions

SB_BUTTONS = {
    'change_password': {
        'title': 'sb_change_password',
        'icon': '/usr/share/icons/Tela/22/emblems/emblem-readonly.svg',
        'command': {
            'type': 'webwindow',
            'args': 'https://$(puavo_domain)/users/password/own?changing=$(user_name)&' \
                    'lang=$(user_language)$(password_tabs)',
            'have_vars': True,
            'webwindow': {
                'title': 'sb_change_password_window_title',
                'width': 1000,
                'height': 650,
                'enable_js': True,
            },
        },
    },

    'support': {
        'title': 'sb_support',
        'icon': '/usr/share/icons/Tela/22/emblems/emblem-question.svg',
        'command': {
            'type': 'url',
            'args': '$(support_url)',
            'have_vars': True,
        },
    },

    'laptop_settings': {
        'title': 'sb_laptop_setup',
        'icon': '/usr/share/icons/Tela/32/devices/computer-laptop.svg',
        'command': {
            'type': 'command',
            'args': 'puavo-laptop-setup',
        },
    },

    'puavopkg_installer': {
        'title': 'sb_puavopkg_installer',
        'icon': '/usr/share/icons/Tela/scalable/apps/system-software-install.svg',
        'command': {
            'type': 'command',
            'args': 'puavo-pkgs-ui',
        },
    },

    'system_settings': {
        'title': 'sb_system_settings',
        'icon': '/usr/share/icons/Tela/scalable/apps/systemsettings.svg',
        'command': {
            'type': 'command',
            'args': 'gnome-control-center',
        },
    },

    'lock_screen': {
        'title': 'sb_lock_screen',
        'icon': '/usr/share/icons/Tela/scalable/apps/system-lock-screen.svg',
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
    },

    'sleep_mode': {
        'title': 'sb_hibernate',
        'icon': '/usr/share/icons/Tela/scalable/apps/system-suspend-hibernate.svg',
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
    },

    'logout': {
        'title': 'sb_logout',
        'icon': '/usr/share/icons/Papirus/64x64/apps/gnome-logout.svg',
        'command': {
            'type': 'command',
            'args': 'gnome-session-quit --logout'
        },
    },

    'restart': {
        'title': 'sb_restart',
        'icon': '/usr/share/icons/Tela/scalable/apps/system-restart.svg',
        'command': {
            'type': 'command',
            'args': 'gnome-session-quit --reboot'
        }
    },

    'shutdown': {
        'title': 'sb_shutdown',
        'icon': '/usr/share/icons/Tela/scalable/apps/system-shutdown.svg',
        'command': {
            'type': 'command',
            'args': 'gnome-session-quit --power-off'
        }
    }
}
