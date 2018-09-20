# The Sidebar: the user avatar, "system" buttons and the host info

from os import environ
from os.path import exists as file_exists, join as path_join
from getpass import getuser
import threading

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk
from gi.repository import Pango

from constants import WINDOW_HEIGHT, MAIN_PADDING, SIDEBAR_WIDTH, \
                      USER_AVATAR_SIZE, HOSTINFO_LABEL_HEIGHT, SEPARATOR_SIZE
import logger
from utils import localize, expand_variables, get_file_contents, puavo_conf
from utils_gui import load_image_at_size, create_separator

from iconcache import ICONS32
from buttons import AvatarButton, SidebarButton
from strings import STRINGS


# ------------------------------------------------------------------------------
# Sidebar button definitions

SB_CHANGE_PASSWORD = {
    'name': 'change_password',

    'title': STRINGS['sb_change_password'],

    'icon': '/usr/share/icons/Faenza/emblems/96/emblem-readonly.png',

    'command': {
        'type': 'webwindow',
        'args': 'https://$(puavo_domain)/users/password/own?changing=$(user_name)',
        'have_vars': True,
    },
}

SB_SUPPORT = {
    'name': 'support',

    'title': STRINGS['sb_support'],

    'icon': '/usr/share/icons/Faenza/status/96/dialog-question.png',

    'command': {
        'type': 'url',
        'args': puavo_conf('puavo.support.new_bugreport_url',
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

    series = get_file_contents('/etc/puavo-image/class', 'opinsys')
    version = get_file_contents('/etc/puavo-image/name', '')

    logger.debug('The current image series is "{0}"'.format(series))
    logger.debug('The current image version is "{0}"'.format(version))

    if len(version) > 4:
        # strip extension from the image file name
        version = version[:-4]

    url = puavo_conf('puavo.support.image_changelog_url',
                     'http://changelog.opinsys.fi')

    url = url.replace('%%IMAGESERIES%%', series)
    url = url.replace('%%IMAGEVERSION%%', version)

    logger.info('The final changelog URL is "{0}"'.format(url))

    return url


class AvatarDownloaderThread(threading.Thread):
    """Downloads the user avatar from the API server, caches it and
    updates the avatar icon."""

    def __init__(self, destination, avatar_object):
        super().__init__()
        self.__destination = destination        # where to cache the file
        self.__avatar_object = avatar_object    # the avatar button object


    def run(self):
        import time             # oh, I wish
        import subprocess

        # Wait until everything else has been loaded
        time.sleep(30)

        # How many times we'll keep trying until giving up?
        MAX_ATTEMPTS = 10

        for attempt in range(0, MAX_ATTEMPTS):
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
                logger.info('Downloading user avatar from "{2}", ' \
                            'attempt {0}/{1}...'.
                            format(attempt + 1, MAX_ATTEMPTS, uri))

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

                logger.info('Downloaded {0} bytes of avatar image data ' \
                            'in {1:.1f} ms'.
                            format(len(image),
                                   (time.clock() - start_time) * 1000.0))

                # Wrap this in its own exception handler, so if it fails,
                # we just return instead of redownloading the image
                try:
                    name = path_join(self.__destination, 'avatar.jpg')
                    open(name, 'wb').write(image)
                    self.__avatar_object.load_avatar(name)
                except Exception as e:
                    # Why must everything fail?
                    logger.warn('Failed to save the downloaded avatar ' \
                                'image: {0}'.format(e))
                    logger.warn('New avatar image not set')

                logger.info('Avatar thread is exiting')
                return
            except Exception as error:
                logger.error('Could not download the user avatar: {0}'.
                             format(error))

            # Retry, if possible
            if attempt < MAX_ATTEMPTS - 1:
                import time
                logger.info('Retrying avatar downloading in 60 seconds...')
                time.sleep(60)

        logger.error('Giving up on trying to download the user avatar, ' \
                     'tried {0} times'.format(MAX_ATTEMPTS))
        logger.info('Avatar thread is exiting')


# ------------------------------------------------------------------------------
# The sidebar class

class Sidebar:
    def __init__(self, parent, language, res_dir, user_dir, dark=False):
        self.__parent = parent
        self.__language = language
        self.__res_dir = res_dir
        self.__user_dir = user_dir
        self.__dark = dark

        self.container = Gtk.Fixed()

        self.__detect_host_params()
        self.__get_variables()

        self.__create_avatar()
        self.__create_buttons()
        self.__create_hostinfo()

        self.container.show()

        # Download a new copy of the user avatar image
        if self.__must_download_avatar:
            logger.info('Launching a background thread for downloading ' \
                        'the avatar image')

            try:
                self.__avatar_thread = \
                    AvatarDownloaderThread(self.__user_dir, self.__avatar)

                # Daemonize the thread so that if we exit before
                # the thread exists, it is also destroyed
                self.__avatar_thread.daemon = True

                self.__avatar_thread.start()
            except Exception as e:
                logger.error('Could not create a new thread: {0}'.format(e))


    # Detects various settings for the current host and session
    def __detect_host_params(self):
        self.__is_guest = False
        self.__is_fatclient = False
        self.__is_webkiosk = False

        # Detect guest user sessions
        if 'GUEST_SESSION' in environ:
            logger.info('This is a guest user session.')
            self.__is_guest = True

        # Detect fatclients
        device_type = puavo_conf('puavo.hosttype', 'laptop')

        if device_type == 'fatclient':
            logger.info('This is a fatclient device')
            self.__is_fatclient = True

        # Detect webkiosk sessions. I don't know if this actually works!
        if puavo_conf('puavo.webmenu.webkiosk', '') == 'true':
            logger.info('This is a webkiosk session')
            self.__is_webkiosk = True


    # Digs up values for expanding variables in button arguments
    def __get_variables(self):
        self.__variables = {}
        self.__variables['puavo_domain'] = \
            get_file_contents('/etc/puavo/domain', '?')
        self.__variables['user_name'] = getuser()


    # Creates the user avatar button
    def __create_avatar(self):
        self.__must_download_avatar = True

        default_avatar = path_join(self.__res_dir, 'default_avatar.png')
        existing_avatar = path_join(self.__user_dir, 'avatar.jpg')

        if self.__is_guest or self.__is_webkiosk:
            # Always use the default avatar for guests and webkiosk sessions
            logger.info('Not loading avatar for a guest/webkiosk session')
            avatar_image = default_avatar
            self.__must_download_avatar = False
        elif file_exists(existing_avatar):
            logger.info('A previously-downloaded user avatar file exists, using it')
            avatar_image = existing_avatar
        else:
            # We need to download this avatar image right away, use the
            # default avatar until the download is complete
            logger.info('Not a guest/webkiosk session and no previously-' \
                        'downloaded avatar available, using the default image')
            avatar_image = default_avatar

        if self.__is_guest or self.__is_webkiosk:
            avatar_tooltip = None
        else:
            avatar_tooltip = localize(STRINGS['sb_avatar_hover'],
                                      self.__language)

        self.__avatar = AvatarButton(self,
                                     getuser(),
                                     avatar_image,
                                     avatar_tooltip,
                                     dark=self.__dark)

        # No profile editing for guest users
        if self.__is_guest or self.__is_webkiosk:
            logger.info('Disabling the avatar button for guest user')
            self.__avatar.disable()
        else:
            self.__avatar.connect('clicked', self.__clicked_avatar_button)

        self.container.put(self.__avatar, 0, MAIN_PADDING)
        self.__avatar.show()


    # Creates the sidebar "system" buttons
    def __create_buttons(self):
        create_separator(container=self.container,
                         x=0,
                         y=MAIN_PADDING + USER_AVATAR_SIZE + MAIN_PADDING,
                         w=SIDEBAR_WIDTH,
                         h=-1,
                         orientation=Gtk.Orientation.HORIZONTAL)

        y = MAIN_PADDING + USER_AVATAR_SIZE + MAIN_PADDING * 2 + SEPARATOR_SIZE

        # Since Python won't let you modify arguments (no pass-by-reference),
        # each of these returns the next Y position. X coordinates are fixed.

        if not (self.__is_guest or self.__is_webkiosk):
            y = self.__create_button(y, SB_CHANGE_PASSWORD)

        y = self.__create_button(y, SB_SUPPORT)
        y = self.__create_button(y, SB_SYSTEM_SETTINGS)
        y = self.__create_separator(y)

        if not (self.__is_guest or self.__is_webkiosk):
            y = self.__create_button(y, SB_LOCK_SCREEN)

        if not (self.__is_fatclient or self.__is_webkiosk):
            y = self.__create_button(y, SB_SLEEP_MODE)

        y = self.__create_button(y, SB_LOGOUT)
        y = self.__create_separator(y)
        y = self.__create_button(y, SB_RESTART)

        if not self.__is_webkiosk:
            y = self.__create_button(y, SB_SHUTDOWN)

        logger.info('Support page URL: "{0}"'.
                    format(SB_SUPPORT['command']['args']))


    # Creates a sidebar button
    def __create_button(self, y, data):
        button = SidebarButton(self,
                               localize(data['title'], self.__language),
                               ICONS32.load_icon(data['icon']),
                               localize(data.get('description', ''), self.__language),
                               data['command'],
                               dark=self.__dark)

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
        return y + MAIN_PADDING * 2 + SEPARATOR_SIZE


    # Builds the label that contains hostname, host type, image name and
    # a link to the changelog.
    def __create_hostinfo(self):
        label_top = WINDOW_HEIGHT - MAIN_PADDING - HOSTINFO_LABEL_HEIGHT

        create_separator(container=self.container,
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

        # "big" and "small" are not good sizes, we need to be explicit
        hostname_label.set_markup(
            '<big>{0}</big>\n<small><a href="{3}" title="{4}">{1}</a> ({2})</small>'.
            format(get_file_contents('/etc/puavo/hostname'),
                   get_file_contents('/etc/puavo-image/release'),
                   get_file_contents('/etc/puavo/hosttype'),
                   get_changelog_url(),
                   localize(STRINGS['sb_changelog_title'], self.__language)))

        hostname_label.show()
        self.container.put(hostname_label, 0, label_top)


    # Open the user profile editor
    def __clicked_avatar_button(self, button):
        print('Clicked the user avatar button')

        url = expand_variables('https://$(puavo_domain)/users/profile/edit',
                               self.__variables)

        try:
            # open the URL in the default web browser
            import subprocess

            subprocess.Popen(['xdg-open', url],
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        except Exception as exception:
            logger.error(str(exception))
            self.__parent.error_message(
                localize(STRINGS['sb_avatar_link_failed'], self.__language),
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
