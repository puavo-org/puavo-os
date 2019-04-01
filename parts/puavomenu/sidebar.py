# The Sidebar: the user avatar, "system" buttons and the host info

from os.path import exists as file_exists, join as path_join
from getpass import getuser
import threading
import logging

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk
from gi.repository import Pango

from constants import WINDOW_HEIGHT, MAIN_PADDING, SIDEBAR_WIDTH, \
                      USER_AVATAR_SIZE, HOSTINFO_LABEL_HEIGHT, SEPARATOR_SIZE

import utils
import utils_gui
from iconcache import ICONS32
import buttons
from strings import STRINGS
from settings import SETTINGS


# ------------------------------------------------------------------------------
# Sidebar button definitions

SB_CHANGE_PASSWORD = {
    'name': 'change_password',

    'title': STRINGS['sb_change_password'],

    'icon': '/usr/share/icons/Faenza/emblems/96/emblem-readonly.png',

    'command': {
        'type': 'webwindow',
        'args': 'https://$(puavo_domain)/users/password/own?changing=$(user_name)&lang=$(user_language)',
        'have_vars': True,
        'webwindow': {
            'title': STRINGS['sb_change_password_window_title'],
            'width': 1000,
            'height': 700,
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
        'args': ['dbus-send',
                 '--type=method_call',
                 '--dest=org.gnome.ScreenSaver',
                 '/org/gnome/ScreenSaver',
                 'org.gnome.ScreenSaver.Lock']
    },
}

SB_SLEEP_MODE = {
    'name': 'sleep-mode',

    'title': STRINGS['sb_hibernate'],

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


def get_changelog_url():
    """Generates the full URL to the current image's changelog."""

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


def web_window(url, title=None, width=None, height=None,
               enable_js=False, enable_plugins=False):
    """puavo-webwindow call wrapper. Remember to handle exceptions."""

    import subprocess

    cmd = ['puavo-webwindow', '--url', str(url)]

    if title:
        cmd += ['--title', str(title)]

    if width:
        cmd += ['--width', str(width)]

    if height:
        cmd += ['--height', str(height)]

    if enable_js:
        cmd += ['--enable-js']

    if enable_plugins:
        cmd += ['--enable-plugins']

    logging.info('Opening a webwindow: "%s"', cmd)

    subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


class AvatarDownloaderThread(threading.Thread):
    """Downloads the user avatar from the API server, caches it and
    updates the avatar icon."""

    # How long to wait until we start downloading the avatar image?
    INITIAL_WAIT = 30

    # How long to wait between avatar download retries?
    RETRY_WAIT = 60

    # How many times we'll keep trying until giving up?
    MAX_ATTEMPTS = 10

    def __init__(self, destination, avatar_object):
        super().__init__()
        self.__destination = destination        # where to cache the file
        self.__avatar_object = avatar_object    # the avatar button object


    def run(self):
        import time             # oh, I wish
        import subprocess

        time.sleep(self.INITIAL_WAIT)

        logging.info('The avatar update thread is starting')

        for attempt in range(0, self.MAX_ATTEMPTS):
            try:
                # Figure out the API server address
                proc = subprocess.Popen(['puavo-resolve-api-server'],
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE)
                proc.wait()

                if proc.returncode != 0:
                    raise RuntimeError("'puavo-resolve-api-server' failed " \
                                       "with code {0}".format(proc.returncode))

                server = proc.stdout.read().decode('utf-8').strip()
                uri = server + '/v3/users/' + getuser() + '/profile.jpg'

                # Then download the avatar image
                logging.info('Downloading user avatar from "%s", ' \
                             'attempt %d/%d...', uri, attempt + 1,
                             self.MAX_ATTEMPTS)

                start_time = time.clock()

                # I gave up pretty quickly on trying to replicate this in
                # Python's http.client. It needs Kerberos authentication
                # and other bells and whistles. I probably could figure
                # it out, but I'd just introduce subtle bugs in it. Let
                # curl deal with it.
                command = [
                    'curl',
                    '--fail',
                    '--negotiate', '--user', ':',
                    '--delegation', 'always',
                    uri
                ]

                proc = subprocess.Popen(command,
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE)
                proc.wait()

                if proc.returncode != 0:
                    raise RuntimeError("'curl' failed with code {0}".
                                       format(proc.returncode))

                # Got it! We didn't specify -o, so the image data waits for
                # us in stdout.
                image = proc.stdout.read()

                logging.info('Downloaded %d bytes of avatar image data in %s ms',
                             len(image),
                             '{0:.1f}'.format((time.clock() - start_time) * 1000.0))

                # Wrap this in its own exception handler, so if it fails,
                # we just return instead of redownloading the image
                try:
                    logging.info('Saving the avatar image to %s',
                                 self.__destination)
                    name = path_join(self.__destination, 'avatar.jpg')
                    open(name, 'wb').write(image)
                    self.__avatar_object.load_avatar(name)
                except Exception as exception:
                    # Why must everything fail?
                    logging.warning('Failed to save the downloaded avatar ' \
                                    'image: %s', str(exception))
                    logging.warning('New avatar image not set')

                logging.info('The avatar update thread is exiting')
                return
            except Exception as exception:
                logging.error('Could not download the user avatar: %s',
                              str(exception))

            # Retry, if possible
            if attempt < self.MAX_ATTEMPTS - 1:
                logging.info('Retrying avatar downloading in %d seconds...',
                             self.RETRY_WAIT)
                time.sleep(self.RETRY_WAIT)

        logging.error('Giving up on trying to download the user avatar, ' \
                      'tried %d times', self.MAX_ATTEMPTS)
        logging.info('The avatar update thread is exiting')


# ------------------------------------------------------------------------------
# The sidebar class

class Sidebar:
    def __init__(self, parent):
        self.__parent = parent

        self.container = Gtk.Fixed()

        self.__get_variables()
        self.__create_avatar()
        self.__create_buttons()
        self.__create_hostinfo()

        self.container.show()

        # Download a new copy of the user avatar image
        if self.__must_download_avatar:
            logging.info('Launching a background thread for downloading ' \
                         'the avatar image')

            try:
                self.__avatar_thread = \
                    AvatarDownloaderThread(SETTINGS.user_dir, self.__avatar)

                # Daemonize the thread so that if we exit before
                # the thread exists, it is also destroyed
                self.__avatar_thread.daemon = True

                self.__avatar_thread.start()
            except Exception as exception:
                logging.error('Could not create a new thread: %s',
                              str(exception))


    # Digs up values for expanding variables in button arguments
    def __get_variables(self):
        self.__variables = {}
        self.__variables['puavo_domain'] = \
            utils.get_file_contents('/etc/puavo/domain', '?')
        self.__variables['user_name'] = getuser()
        self.__variables['user_language'] = SETTINGS.language


    # Creates the user avatar button
    def __create_avatar(self):
        self.__must_download_avatar = True

        default_avatar = path_join(SETTINGS.res_dir, 'default_avatar.png')
        existing_avatar = path_join(SETTINGS.user_dir, 'avatar.jpg')

        if SETTINGS.is_guest or SETTINGS.is_webkiosk:
            # Always use the default avatar for guests and webkiosk sessions
            logging.info('Not loading avatar for a guest/webkiosk session')
            avatar_image = default_avatar
            self.__must_download_avatar = False
        elif file_exists(existing_avatar):
            logging.info('A previously-downloaded user avatar file exists, using it')
            avatar_image = existing_avatar
        else:
            # We need to download this avatar image right away, use the
            # default avatar until the download is complete
            logging.info('Not a guest/webkiosk session and no previously-' \
                         'downloaded avatar available, using the default image')
            avatar_image = default_avatar

        if SETTINGS.is_guest or SETTINGS.is_webkiosk:
            avatar_tooltip = None
        else:
            avatar_tooltip = utils.localize(STRINGS['sb_avatar_hover'])

        self.__avatar = buttons.AvatarButton(self, getuser(), avatar_image,
                                             avatar_tooltip)

        # No profile editing for guest users
        if SETTINGS.is_guest or SETTINGS.is_webkiosk:
            logging.info('Disabling the avatar button for guest user')
            self.__avatar.disable()
        else:
            self.__avatar.connect('clicked', self.__clicked_avatar_button)

        self.container.put(self.__avatar, 0, MAIN_PADDING)
        self.__avatar.show()


    # Creates the sidebar "system" buttons
    def __create_buttons(self):
        utils_gui.create_separator(
            container=self.container,
            x=0,
            y=MAIN_PADDING + USER_AVATAR_SIZE + MAIN_PADDING,
            w=SIDEBAR_WIDTH,
            h=-1,
            orientation=Gtk.Orientation.HORIZONTAL)

        y = MAIN_PADDING + USER_AVATAR_SIZE + MAIN_PADDING * 2 + SEPARATOR_SIZE

        # Since Python won't let you modify arguments (no pass-by-reference),
        # each of these returns the next Y position. X coordinates are fixed.

        if not (SETTINGS.is_guest or SETTINGS.is_webkiosk):
            y = self.__create_button(y, SB_CHANGE_PASSWORD)

        y = self.__create_button(y, SB_SUPPORT)
        y = self.__create_button(y, SB_SYSTEM_SETTINGS)
        y = self.__create_separator(y)

        if not (SETTINGS.is_guest or SETTINGS.is_webkiosk):
            y = self.__create_button(y, SB_LOCK_SCREEN)

        if not (SETTINGS.is_fatclient or SETTINGS.is_webkiosk):
            y = self.__create_button(y, SB_SLEEP_MODE)

        y = self.__create_button(y, SB_LOGOUT)
        y = self.__create_separator(y)
        y = self.__create_button(y, SB_RESTART)

        if not SETTINGS.is_webkiosk:
            y = self.__create_button(y, SB_SHUTDOWN)

        logging.info('Support page URL: "%s"', SB_SUPPORT['command']['args'])


    # Creates a sidebar button
    def __create_button(self, y, data):
        button = buttons.SidebarButton(self,
                                       utils.localize(data['title']),
                                       ICONS32.load_icon(data['icon']),
                                       utils.localize(data.get('description', '')),
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


    # Builds the label that contains hostname, host type, image name and
    # a link to the changelog.
    def __create_hostinfo(self):
        label_top = WINDOW_HEIGHT - MAIN_PADDING - HOSTINFO_LABEL_HEIGHT

        utils_gui.create_separator(
            container=self.container,
            x=0,
            y=label_top - MAIN_PADDING,
            w=SIDEBAR_WIDTH,
            h=1,
            orientation=Gtk.Orientation.HORIZONTAL)

        hostname_label = Gtk.Label()
        hostname_label.set_size_request(SIDEBAR_WIDTH, HOSTINFO_LABEL_HEIGHT)
        hostname_label.set_ellipsize(Pango.EllipsizeMode.END)
        hostname_label.set_justify(Gtk.Justification.CENTER)
        hostname_label.set_alignment(0.5, 0.5)
        hostname_label.set_use_markup(True)

        # FIXME: "big" and "small" are not good sizes, we need to be explicit
        hostname_label.set_markup(
            '<big>{0}</big>\n<small><a href="{3}" title="{4}">{1}</a> ({2})</small>'.
            format(utils.get_file_contents('/etc/puavo/hostname'),
                   utils.get_file_contents('/etc/puavo-image/release'),
                   utils.get_file_contents('/etc/puavo/hosttype'),
                   '',
                   utils.localize(STRINGS['sb_changelog_title'])))

        hostname_label.connect('activate-link', self.__clicked_changelog)
        hostname_label.show()
        self.container.put(hostname_label, 0, label_top)


    # Open the user profile editor
    def __clicked_avatar_button(self, _):
        print('Clicked the user avatar button')

        try:
            web_window(
                url=utils.expand_variables(
                    'https://$(puavo_domain)/users/profile/edit?lang=$(user_language)',
                    self.__variables),
                title=utils.localize(STRINGS['sb_avatar_hover']),
                width=1000,
                height=700,
                enable_js=True)     # The profile editor needs JavaScript
        except Exception as exception:
            logging.error(str(exception))
            self.__parent.error_message(
                utils.localize(STRINGS['sb_avatar_link_failed']),
                str(exception))

        self.__parent.autohide()


    # Open the changelog
    def __clicked_changelog(self, *unused):
        try:
            web_window(
                url=get_changelog_url(),
                title=utils.localize(STRINGS['sb_changelog_window_title']),
                width=1000,
                height=700,
                enable_js=True)     # Markdown is used on the page, need JS
        except Exception as exception:
            logging.error(str(exception))
            self.__parent.error_message(
                utils.localize(STRINGS['sb_changelog_link_failed']),
                str(exception))

        self.__parent.autohide()


    # Sidebar button command handler
    def __clicked_sidebar_button(self, button):
        try:
            import subprocess

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
                subprocess.Popen(['sh', '-c', arguments, '&'],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            elif command['type'] == 'url':
                logging.info('Opening a URL')
                subprocess.Popen(['xdg-open', arguments],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
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
                        title = utils.localize(title)

                web_window(
                    url=arguments,
                    title=title,
                    width=width,
                    height=height,
                    enable_js=enable_js)
        except Exception as exception:
            logging.error('Could not process a sidebar button click!')
            logging.error(str(exception))
            self.__parent.error_message(
                utils.localize(STRINGS['sb_button_failed']),
                str(exception))
