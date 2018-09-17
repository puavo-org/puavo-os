# The Sidebar: the user avatar, "system" buttons and the host info

from os import environ
from getpass import getuser

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk
from gi.repository import Pango

from constants import *
import logger
from utils import localize, expand_variables, get_file_contents, \
                  load_image_at_size
from utils_gui import create_separator

from iconcache import ICONS32
from buttons import AvatarButton, SidebarButton

# ------------------------------------------------------------------------------
# Sidebar button definitions

sb_change_password = {
    'name': 'change_password',

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
}

sb_support = {
    'name': 'support',

    'title': {
        'en': 'Support',
        'fi': 'Tukisivusto',
        'sv': 'Support',
        'de': 'Support',
    },

    'description': '',

    'icon': '/usr/share/icons/Faenza/status/96/dialog-question.png',

    'command': {
        'type': 'url',
        'args': 'https://tuki.opinsys.fi'
    },
}

sb_system_settings = {
    'name': 'system-settings',

    'title': {
        'en': 'System settings',
        'fi': 'Järjestelmän asetukset',
        'sv': 'Systeminställningar',
        'de': 'Systemeinstellungen',
    },

    'description': '',

    'icon': '/usr/share/icons/Faenza/categories/96/applications-system.png',

    'command': {
        'type': 'command',
        'args': 'gnome-control-center',
    },
}

sb_lock_screen = {
    'name': 'lock-screen',

    'title': {
        'en': 'Lock screen',
        'fi': 'Lukitse näyttö',
        'sv': 'Lås skärmen',
        'de': 'Bildschirm sperren'
    },

    'description': '',

    'icon': '/usr/share/icons/Faenza/actions/96/system-lock-screen.png',

    'command': {
        'type': 'command',
        'args': ['dbus-send',
                 '--type=method_call',
                 '--dest=org.gnome.ScreenSaver',
                 '/org/gnome/ScreenSaver',
                 'org.gnome.ScreenSaver.Lock']
    },
}

sb_sleep_mode = {
    'name': 'sleep-mode',

    'title': {
        'en': 'Sleep',
        'fi': 'Unitila',
        'sv': 'Strömsparläge',
        'de': 'Schlafen'
    },

    'description': '',

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
}

sb_logout = {
    'name': 'logout',

    'title': {
        'en': 'Logout',
        'fi': 'Kirjaudu ulos',
        'sv': 'Logga ut',
        'de': 'Abmelden'
    },

    'description': '',

    'icon': '/usr/share/icons/gnome/32x32/actions/gnome-session-logout.png',

    'command': {
        'type': 'command',
        'args': 'gnome-session-quit --logout'
    },
}

sb_restart = {
    'name': 'restart',

    'title': {
        'en': 'Restart',
        'fi': 'Käynnistä uudelleen',
        'sv': 'Starta om',
        'de': 'Neustarten'
    },

    'description': '',

    'icon': '/usr/share/icons/oxygen/base/32x32/actions/system-reboot.png',

    'command': {
        'type': 'command',
        'args': 'gnome-session-quit --reboot'
    }
}

sb_shutdown = {
    'name': 'shutdown',

    'title': {
        'en': 'Shut down',
        'fi': 'Sammuta',
        'sv': 'Stäng av',
        'de': 'Herunterfahren',
    },

    'description': '',

    'icon': '/usr/share/icons/oxygen/base/32x32/actions/system-shutdown.png',

    'command': {
        'type': 'command',
        'args': 'gnome-session-quit --power-off'
    }
}

# ------------------------------------------------------------------------------
# The sidebar class

class Sidebar:
    STRINGS = {
        'avatar_link_failed': {
            'en': 'Could not open the user preferences editor',
            'fi': 'Ei voitu avata käyttäjätietojen muokkausta',
        }
    }

    def __init__(self, parent, language, res_dir):
        self.__parent = parent
        self.__language = language

        # Sidebar container
        self.container = Gtk.Fixed()

        # Detect guest user sessions
        if 'GUEST_SESSION' in environ:
            logger.info('This is a guest user session.')
            self.__is_guest = True
        else:
            self.__is_guest = False

        # Variables for commands
        self.__variables = {}
        self.__variables['puavo_domain'] = \
            get_file_contents('/etc/puavo/domain')
        self.__variables['user_name'] = getuser()

        # User name and avatar icon
        try:
            avatar_image = \
                load_image_at_size(res_dir + 'default_avatar.png', 48, 48)
        except Exception as e:
            logger.error('Can\'t load the default avatar image: {0}'.
                         format(e))
            avatar_image = None

        avatar = AvatarButton(self, getuser(), avatar_image)

        if self.__is_guest:
            logger.info('Disabling the avatar button for guest user')
            avatar.disable()
        else:
            avatar.connect('clicked', self.__clicked_avatar_button)

        self.container.put(avatar, 0, MAIN_PADDING)
        avatar.show()

        # The buttons
        create_separator(container=self.container,
                         x=0,
                         y=MAIN_PADDING + USER_AVATAR_SIZE + MAIN_PADDING,
                         w=SIDEBAR_WIDTH,
                         h=-1,
                         orientation=Gtk.Orientation.HORIZONTAL)

        self.__create_buttons()

        # Host name and release name/type
        label_top = WINDOW_HEIGHT - MAIN_PADDING - LABEL_HEIGHT

        create_separator(container=self.container,
                         x=0,
                         y=label_top - MAIN_PADDING,
                         w=SIDEBAR_WIDTH,
                         h=1,
                         orientation=Gtk.Orientation.HORIZONTAL)

        hostname_label = Gtk.Label()
        hostname_label.set_size_request(SIDEBAR_WIDTH, LABEL_HEIGHT)
        hostname_label.set_ellipsize(Pango.EllipsizeMode.END)
        hostname_label.set_justify(Gtk.Justification.CENTER)
        hostname_label.set_alignment(0.5, 0.5)
        hostname_label.set_use_markup(True)

        # "big" and "small" are not good sizes, we need to be explicit
        hostname_label.set_markup(
            '<big>{hn}</big>\n<small>{rn} ({ht})</small>'.format(
            hn=get_file_contents('/etc/puavo/hostname'),
            rn=get_file_contents('/etc/puavo-image/release'),
            ht=get_file_contents('/etc/puavo/hosttype')))

        hostname_label.show()
        self.container.put(hostname_label, 0, label_top)

        self.container.show()


    def __create_buttons(self):
        # FIXME: the "+1" is a hack, it must be changed if the separator
        # height ever changes.
        y = MAIN_PADDING + USER_AVATAR_SIZE + MAIN_PADDING * 2 + 1

        # Since Python won't let you modify arguments (no pass-by-reference),
        # each of these returns the next Y position. X coordinates are fixed.

        if not self.__is_guest:
            y = self.__create_button(y, sb_change_password)

        y = self.__create_button(y, sb_support)
        y = self.__create_button(y, sb_system_settings)
        y = self.__create_separator(y)

        if not self.__is_guest:
            y = self.__create_button(y, sb_lock_screen)

        y = self.__create_button(y, sb_sleep_mode)
        y = self.__create_button(y, sb_logout)
        y = self.__create_separator(y)
        y = self.__create_button(y, sb_restart)
        y = self.__create_button(y, sb_shutdown)


    # Creates a sidebar button
    def __create_button(self, y, data):
        button = SidebarButton(self,
                               localize(data['title'], self.__language),
                               ICONS32.load_icon(data['icon']),
                               localize(data['description'], self.__language),
                               data['command'])

        button.connect('clicked', self.__clicked_sidebar_button)
        button.show()
        self.container.put(button, 0, y)

        # the next available Y coordinate
        return y + button.get_preferred_button_size()[1]


    # Creates a special sidebar separator
    def __create_separator(self, y):
        SEP_PADDING = 20

        create_separator(container=self.container,
                         x=SEP_PADDING,
                         y=y + MAIN_PADDING,
                         w=SIDEBAR_WIDTH - SEP_PADDING * 2,
                         h=-1,
                         orientation=Gtk.Orientation.HORIZONTAL)

        # the next available Y coordinate
        # FIXME: the "+1" is a hack, it must be changed if the separator
        # height ever changes.
        return y + MAIN_PADDING * 2 + 1


    # Edit user preferences
    def __clicked_avatar_button(self, e):
        print('Clicked the user avatar button')

        url = expand_variables('https://$(puavo_domain)/users/profile/edit',
                               self.__variables)

        try:
            # open the URL in the default web browser
            import subprocess

            subprocess.Popen(['xdg-open', url],
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        except Exception as e:
            logger.error(str(e))
            self.__parent.error_message(
                localize(self.STRINGS['avatar_link_failed'], self.language),
                str(e))

        self.__parent.autohide()


    # Clicked a sidebar button
    def __clicked_sidebar_button(self, button):
        try:
            import subprocess

            command = button.data
            arguments = command.get('args', '')

            # Support plain strings and arrays of strings as arguments
            if isinstance(arguments, list):
                arguments = ' '.join(arguments).strip()

            if len(arguments) == 0:
                logger.error('Sidebar button without a command!')
                self.__parent.error_message(
                    'Nothing to do',
                    'This button has no commands associated with it.')
                return

            self.__parent.autohide()

            # Expand variables
            if command.get('have_vars', False):
                arguments = expand_variables(arguments, self.__variables)

            logger.debug('Sidebar button arguments: "{0}"'.
                         format(arguments))

            if command['type'] == 'command':
                logger.info('Executing a command')
                subprocess.Popen(['sh', '-c', arguments, '&'],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            elif command['type'] == 'url':
                logger.info('Opening a URL')
                subprocess.Popen(['xdg-open', arguments],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            elif command['type'] == 'webwindow':
                # TODO: implement this, don't open a separate browser window
                logger.info('Creating a webwindow')
                subprocess.Popen(['xdg-open', arguments],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
        except Exception as e:
            logger.error('Could not process a sidebar button click!')
            logger.error(e)
