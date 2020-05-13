# The Sidebar: the user avatar, "system" buttons and the host info

import logging
import threading
import getpass
import os.path

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk
from gi.repository import Pango
from gi.repository import Gio

from constants import WINDOW_HEIGHT, MAIN_PADDING, SIDEBAR_WIDTH, SIDEBAR_HEIGHT, \
                      USER_AVATAR_SIZE, HOSTINFO_LABEL_HEIGHT, SEPARATOR_SIZE

import utils
import utils_gui
import icons
import buttons.sidebar, buttons.avatar

from strings import STRINGS

from sidebar.button_definitions import *

from sidebar.avatar_downloader import AvatarDownloaderThread


# Generates the full URL to the current image's changelog
def get_changelog_url():
    series = utils.get_file_contents('/etc/puavo-image/class', 'opinsys')
    version = utils.get_file_contents('/etc/puavo-image/name', '')

    logging.info('The current image series is "%s"', series)
    logging.info('The current image version is "%s"', version)

    if len(version) > 4:
        # strip the extension from the image file name
        version = version[:-4]

    url = utils.puavo_conf('puavo.support.image_changelog_url',
                           'http://changelog.opinsys.fi')

    url = url.replace('%%IMAGESERIES%%', series)
    url = url.replace('%%IMAGEVERSION%%', version)

    logging.info('The final changelog URL is "%s"', url)

    return url


class Sidebar:
    def __init__(self, parent, settings):
        self.__parent = parent
        self.__settings = settings

        self.container = Gtk.Fixed()
        self.container.set_size_request(SIDEBAR_WIDTH, SIDEBAR_HEIGHT)

        # Storage for the command button icons
        self.__icons = icons.IconCache(128, 32)

        self.__get_variables()
        self.__create_avatar_button()
        self.__create_system_buttons()
        self.__create_hostinfo()

        # Download a new copy of the user avatar image
        if self.__must_download_avatar:
            logging.info(
                'Sidebar::ctor(): launching a background thread for downloading '
                'the avatar image')

            try:
                self.__avatar_thread = AvatarDownloaderThread(
                    self.__settings.user_conf, self.__avatar)

                # Daemonize the thread so that if we exit before
                # the thread exists, it is also destroyed
                self.__avatar_thread.daemon = True

                self.__avatar_thread.start()
            except Exception as exception:
                logging.error(
                    'Sidebar::ctor(): could not create a new thread: %s',
                    str(exception))

        self.container.show()


    # Digs up values for expanding variables in button arguments
    def __get_variables(self):
        self.__variables = {}
        self.__variables['puavo_domain'] = \
            utils.get_file_contents('/etc/puavo/domain', '?')
        self.__variables['user_name'] = getpass.getuser()
        self.__variables['user_language'] = self.__settings.language

        if self.__settings.dark_theme:
            self.__variables['user_theme'] = 'dark'
        else:
            self.__variables['user_theme'] = 'light'

        if self.__settings.user_type not in ('teacher', 'admin'):
            # For non-teachers and non-admins, don't show the "change someone
            # else's password" tab on the password form. Not a very good
            # protection, but it's not the only one we have and it will
            # filter out the most basic hacker wannabes.
            self.__variables['password_tabs'] = '&hidetabs'
        else:
            self.__variables['password_tabs'] = ''


    # Creates the user avatar button
    def __create_avatar_button(self):
        self.__must_download_avatar = True

        default_avatar = os.path.join(self.__settings.res_dir, 'default_avatar.png')
        existing_avatar = os.path.join(self.__settings.user_conf, 'avatar.jpg')

        if self.__settings.is_guest or self.__settings.is_webkiosk:
            # Always use the default avatar for guests and webkiosk sessions
            logging.info('Avatar downloader thread disabled in a guest/webkiosk session')
            avatar_image = default_avatar
            self.__must_download_avatar = False
        elif os.path.exists(existing_avatar):
            logging.info('A previously-downloaded user avatar file exists, using it')
            avatar_image = existing_avatar
        else:
            # We need to download this avatar image right away, use the
            # default avatar until the download is complete
            logging.info('Not a guest/webkiosk session and no previously-'
                         'downloaded avatar available, using the default image')
            avatar_image = default_avatar

        if self.__settings.is_guest or self.__settings.is_webkiosk:
            avatar_tooltip = None
        else:
            avatar_tooltip = \
                utils.localize(STRINGS['sb_avatar_hover'], self.__settings.language)

        self.__avatar = buttons.avatar.AvatarButton(self,
                                             self.__settings,
                                             self.__variables['user_name'],
                                             avatar_image,
                                             avatar_tooltip)

        # No profile editing for guest users
        if self.__settings.is_guest or self.__settings.is_webkiosk:
            logging.info('Disabling the avatar button for guest user')
            self.__avatar.disable()
        else:
            self.__avatar.connect('clicked', self.__clicked_avatar_button)

        self.container.put(self.__avatar, 0, 0)
        self.__avatar.show()


    # Creates the sidebar "system" buttons
    def __create_system_buttons(self):
        utils_gui.create_separator(
            container=self.container,
            x=0,
            y=MAIN_PADDING + USER_AVATAR_SIZE,
            w=SIDEBAR_WIDTH,
            h=-1,
            orientation=Gtk.Orientation.HORIZONTAL)

        y = MAIN_PADDING + USER_AVATAR_SIZE + MAIN_PADDING + SEPARATOR_SIZE

        # Since Python won't let you modify arguments (no pass-by-reference),
        # each of these returns the next Y position. X coordinates are fixed.

        if not (self.__settings.is_guest or self.__settings.is_webkiosk):
            y = self.__create_button(y, SB_CHANGE_PASSWORD)

        y = self.__create_button(y, SB_SUPPORT)
        y = self.__create_button(y, SB_SYSTEM_SETTINGS)

        if self.__settings.is_user_primary_user:
            y = self.__create_button(y, SB_LAPTOP_SETTINGS)
            y = self.__create_button(y, SB_PUAVOPKG_INSTALLER)

        y = self.__create_separator(y)

        if not (self.__settings.is_guest or self.__settings.is_webkiosk):
            y = self.__create_button(y, SB_LOCK_SCREEN)

        if not (self.__settings.is_fatclient or self.__settings.is_webkiosk):
            y = self.__create_button(y, SB_SLEEP_MODE)

        y = self.__create_button(y, SB_LOGOUT)
        y = self.__create_separator(y)
        y = self.__create_button(y, SB_RESTART)

        if not self.__settings.is_webkiosk:
            y = self.__create_button(y, SB_SHUTDOWN)

        logging.info('Support page URL: "%s"', SB_SUPPORT['command']['args'])


    # Builds the label that contains hostname, host type, image name and
    # a link to the changelog.
    def __create_hostinfo(self):
        label_top = SIDEBAR_HEIGHT - HOSTINFO_LABEL_HEIGHT

        utils_gui.create_separator(
            container=self.container,
            x=0,
            y=label_top - MAIN_PADDING,
            w=SIDEBAR_WIDTH,
            h=1,
            orientation=Gtk.Orientation.HORIZONTAL)

        hostname_label = Gtk.Label(name='hostinfo')
        hostname_label.set_size_request(SIDEBAR_WIDTH, HOSTINFO_LABEL_HEIGHT)
        hostname_label.set_ellipsize(Pango.EllipsizeMode.END)
        hostname_label.set_justify(Gtk.Justification.CENTER)
        hostname_label.set_alignment(0.5, 0.5)
        hostname_label.set_use_markup(True)

        # FIXME: "big" and "small" are not good sizes, we need to be explicit
        hostname_label.set_markup(
            '<big>{hostname}</big>\n<small><a href="{url}" title="{title}">{release}</a> ({hosttype})</small>'.
            format(hostname=utils.get_file_contents('/etc/puavo/hostname'),
                   release=utils.get_file_contents('/etc/puavo-image/release'),
                   hosttype=utils.get_file_contents('/etc/puavo/hosttype'),
                   url='',
                   title=utils.localize(STRINGS['sb_changelog_title'], self.__settings.language)))

        hostname_label.connect('activate-link', self.__clicked_changelog)
        hostname_label.show()

        self.container.put(hostname_label, 0, label_top)


    # --------------------------------------------------------------------------
    # Button click handlers


    # Open the user profile editor
    def __clicked_avatar_button(self, _):
        logging.info('Clicked the user avatar button')

        try:
            utils.open_webwindow(
                url=utils.expand_variables(
                    'https://$(puavo_domain)/users/profile/edit?lang=$(user_language)&theme=$(user_theme)',
                    self.__variables),
                title=utils.localize(STRINGS['sb_avatar_hover'], self.__settings.language),
                width=1000,
                height=650,
                enable_js=True)     # The profile editor needs JavaScript
        except Exception as exception:
            logging.error(str(exception))
            self.__parent.error_message(
                utils.localize(STRINGS['sb_avatar_link_failed'], self.__settings.language),
                str(exception))

        self.__parent.autohide()


    # Open the changelog
    def __clicked_changelog(self, *unused):
        try:
            utils.open_webwindow(
                url=utils.expand_variables(get_changelog_url() + '&theme=$(user_theme)', self.__variables),
                title=utils.localize(STRINGS['sb_changelog_window_title'], self.__settings.language),
                width=1000,
                height=650,
                enable_js=True)     # Markdown is used on the page, need JS
        except Exception as exception:
            logging.error(str(exception))
            self.__parent.error_message(
                utils.localize(STRINGS['sb_changelog_link_failed'], self.__settings.language),
                str(exception))

        self.__parent.autohide()


    # Generic sidebar button command handler
    def __clicked_sidebar_button(self, button):
        try:
            command = button.data
            arguments = command.get('args', '')

            # Support plain strings and arrays of strings as arguments
            if isinstance(arguments, list):
                arguments = ' '.join(arguments).strip()

            if len(arguments) == 0:
                logging.error('Sidebar button without a command!')
                self.__parent.error_message(
                    'Nothing to do',
                    'This button has no commands associated with it.')
                return

            self.__parent.autohide()

            # Expand variables
            if command.get('have_vars', False):
                arguments = utils.expand_variables(arguments, self.__variables)

            logging.debug('Sidebar button arguments: "%s"', arguments)

            if command['type'] == 'command':
                logging.info('Executing a command')
                Gio.AppInfo.create_from_commandline(arguments, '', 0).launch()
            elif command['type'] == 'url':
                logging.info('Opening a URL')
                Gio.AppInfo.launch_default_for_uri(arguments, None)
            elif command['type'] == 'webwindow':
                logging.info('Creating a webwindow')

                # Default settings
                title = None
                width = None
                height = None
                enable_js = False

                # Allow the window to be customized
                if 'webwindow' in command:
                    settings = command['webwindow']
                    width = settings.get('width', None)
                    height = settings.get('height', None)
                    title = settings.get('title', None)
                    enable_js = settings.get('enable_js', False)

                    if title:
                        title = utils.localize(title, self.__settings.language)

                utils.open_webwindow(
                    url=arguments,
                    title=title,
                    width=width,
                    height=height,
                    enable_js=enable_js)

                self.__parent.autohide()
        except Exception as exception:
            logging.error('Could not process a sidebar button click!')
            logging.error(str(exception))
            self.__parent.error_message(
                utils.localize(STRINGS['sb_button_failed'], self.__settings.language),
                str(exception))


    # --------------------------------------------------------------------------
    # Utility

    # Creates a sidebar button
    def __create_button(self, y, data):
        button = buttons.sidebar.SidebarButton(
            self,
            self.__settings,
            utils.localize(data['title'], self.__settings.language),
            (self.__icons, self.__icons[data['icon']][0]),
            utils.localize(data.get('description', ''), self.__settings.language),
            data['command'])

        button.connect('clicked', self.__clicked_sidebar_button)
        button.show()
        self.container.put(button, 0, y)

        # the next available Y coordinate
        return y + button.get_preferred_button_size()[1]


    # Creates a special sidebar separator
    def __create_separator(self, y):
        padding = 20

        utils_gui.create_separator(
            container=self.container,
            x=padding,
            y=y + MAIN_PADDING,
            w=SIDEBAR_WIDTH - padding * 2,
            h=-1,
            orientation=Gtk.Orientation.HORIZONTAL)

        # the next available Y coordinate
        return y + MAIN_PADDING * 2 + SEPARATOR_SIZE
