# The Sidebar: the user avatar, "system" buttons and the host info

import re
import logging
import getpass
import os.path
import lsb_release

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk
from gi.repository import Pango
from gi.repository import Gio

from constants import MAIN_PADDING, SIDEBAR_WIDTH, SIDEBAR_HEIGHT, \
                      USER_AVATAR_SIZE, HOSTINFO_LABEL_HEIGHT, SEPARATOR_SIZE

import utils
import utils_gui
import icons
import buttons.sidebar, buttons.avatar

from strings import _tr

from sidebar.button_definitions import SB_BUTTONS

from sidebar.avatar_downloader import AvatarDownloaderThread


# Generates the full URL to the current image's changelog
def get_changelog_url(lang):
    series = utils.get_file_contents('/etc/puavo-image/class')
    version = utils.get_file_contents('/etc/puavo-image/name')
    lsb_codename = lsb_release.get_distro_information()['CODENAME']

    logging.info('The current distribution codename is "%s"', lsb_codename)
    logging.info('The current image series is "%s"', series)
    logging.info('The current image version is "%s"', version)

    if len(version) > 4:
        # strip the extension from the image file name
        version = version[:-4]

    url = utils.puavo_conf('puavo.support.image_changelog_url',
                           'https://changelog.opinsys.fi')

    url = url.replace('%%IMAGESERIES%%', series)
    url = url.replace('%%IMAGEVERSION%%', version)
    url = url.replace('%%LANG%%', lang)
    url = url.replace('%%LSBCODENAME%%', lsb_codename)

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

        # Which sidebar elements are *unconditionally* hidden through puavo-conf?
        # These override EVERYTHING else!
        self.__visibility_override = self.load_overrides()

        self.__get_variables()

        self.__handle_avatar()
        self.__create_system_buttons()
        self.__create_hostinfo()

        self.container.show()


    def load_overrides(self):
        disabled = utils.puavo_conf('puavo.puavomenu.sidebar_hide_elements', '')
        disabled = [t.strip() for t in re.split(r',|;|\ ', str(disabled) if disabled else '')]
        disabled = filter(None, disabled)
        disabled = [d.lower() for d in disabled]

        return set(disabled)


    def is_element_visible(self, name):
        return name not in self.__visibility_override


    # Digs up values for expanding variables in button arguments
    def __get_variables(self):
        self.__variables = {}
        self.__variables['puavo_domain'] = \
            utils.get_file_contents('/etc/puavo/domain')
        self.__variables['user_name'] = getpass.getuser()
        self.__variables['user_language'] = self.__settings.language
        self.__variables['user_primary_school'] = str(self.__settings.user_primary_school)
        self.__variables['support_url'] = \
            utils.puavo_conf('puavo.support.new_bugreport_url', 'https://tuki.opinsys.fi')

        if self.__settings.user_type not in ('teacher', 'admin'):
            # For non-teachers and non-admins, don't show the "change someone
            # else's password" tab on the password form. Not a very good
            # protection, but it's not the only one we have and it will
            # filter out the most basic hacker wannabes.
            self.__variables['password_tabs'] = '&hidetabs'
        else:
            self.__variables['password_tabs'] = ''


    # Creates the user avatar button
    def __handle_avatar(self):
        if not self.is_element_visible('avatar'):
            return

        download_avatar = True
        default_avatar = os.path.join(self.__settings.res_dir, 'default_avatar.png')
        existing_avatar = os.path.join(self.__settings.user_conf, 'avatar.jpg')

        if self.__settings.is_guest or self.__settings.is_webkiosk:
            # Always use the default avatar for guests and webkiosk sessions
            logging.info('Avatar downloader thread disabled in a guest/webkiosk session')
            avatar_image = default_avatar
            download_avatar = False
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
            avatar_tooltip = _tr('sb_avatar_hover')

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

        if download_avatar:
            # Download a new copy of the user avatar image
            logging.info(
                'Sidebar::__handle_avatar(): launching a background thread for downloading '
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


    # Creates the sidebar "system" buttons
    def __create_system_buttons(self):
        ypos = 0

        if self.is_element_visible('avatar'):
            utils_gui.create_separator(
                container=self.container,
                x=0,
                y=MAIN_PADDING + USER_AVATAR_SIZE,
                w=SIDEBAR_WIDTH,
                h=-1,
                orientation=Gtk.Orientation.HORIZONTAL)

            ypos = MAIN_PADDING + USER_AVATAR_SIZE + MAIN_PADDING + SEPARATOR_SIZE

        something = False

        # Since Python won't let you modify arguments (no pass-by-reference),
        # each of these returns the next Y position. X coordinates are fixed.

        if not (self.__settings.is_guest or self.__settings.is_webkiosk):
            if self.is_element_visible('change_password'):
                password_url = utils.puavo_conf('puavo.puavomenu.password_change.link', None)

                if password_url is None or password_url.strip() == '':
                    ypos = self.__create_button(ypos, SB_BUTTONS['change_password'])
                else:
                    # Override the password change URL
                    params = SB_BUTTONS['change_password']
                    params['command']['args'] = password_url
                    ypos = self.__create_button(ypos, params)

                something = True

        if self.is_element_visible('support'):
            ypos = self.__create_button(ypos, SB_BUTTONS['support'])
            something = True

        if self.is_element_visible('system_settings'):
            ypos = self.__create_button(ypos, SB_BUTTONS['system_settings'])
            something = True

        if self.__settings.is_user_primary_user:
            if self.is_element_visible('laptop_settings'):
                ypos = self.__create_button(ypos, SB_BUTTONS['laptop_settings'])
                something = True

            # Hide the puavo-pkg package installer if there
            # are no packages to install
            if utils.puavo_conf('puavo.pkgs.ui.pkglist', '').strip():
                if self.is_element_visible('puavopkg_installer'):
                    ypos = self.__create_button(ypos, SB_BUTTONS['puavopkg_installer'])
                    something = True

        if something:
            ypos = self.__create_separator(ypos)

        if not (self.__settings.is_guest or self.__settings.is_webkiosk):
            if self.is_element_visible('lock_screen'):
                ypos = self.__create_button(ypos, SB_BUTTONS['lock_screen'])

        if not (self.__settings.is_fatclient or self.__settings.is_webkiosk):
            if self.is_element_visible('sleep_mode'):
                ypos = self.__create_button(ypos, SB_BUTTONS['sleep_mode'])

        if self.is_element_visible('logout'):
            ypos = self.__create_button(ypos, SB_BUTTONS['logout'])
            ypos = self.__create_separator(ypos)

        if self.is_element_visible('restart'):
            ypos = self.__create_button(ypos, SB_BUTTONS['restart'])

        if not self.__settings.is_webkiosk:
            if self.is_element_visible('shutdown'):
                ypos = self.__create_button(ypos, SB_BUTTONS['shutdown'])


    # Builds the label that contains hostname, host type, image name and
    # a link to the changelog.
    def __create_hostinfo(self):
        if not self.is_element_visible('hostinfo'):
            return

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
        hostname_label.set_xalign(0.5)
        hostname_label.set_yalign(0.5)
        hostname_label.set_use_markup(True)

        # FIXME: "big" and "small" are not good sizes, we need to be explicit
        hostname_label.set_markup(
            '<big>{hostname}</big><small>\n' \
            '<a href="" title="{title}">{release}</a> ({hosttype})</small>'.
            format(hostname=utils.get_file_contents('/etc/puavo/hostname'),
                   release=utils.get_file_contents('/etc/puavo-image/release'),
                   hosttype=utils.get_file_contents('/etc/puavo/hosttype'),
                   title=_tr('sb_changelog_title')))

        hostname_label.connect('activate-link', self.__clicked_changelog)
        hostname_label.show()

        self.container.put(hostname_label, 0, label_top)


    # --------------------------------------------------------------------------
    # Button click handlers


    # Open the user profile editor
    def __clicked_avatar_button(self, _):
        logging.info('Clicked the user avatar button')

        try:
            url = 'https://$(puavo_domain)/users/profile/edit?' \
                  'lang=$(user_language)'

            utils.open_webwindow(
                url=utils.expand_variables(url, self.__variables),
                title=_tr('sb_avatar_hover'),
                width=1000,
                height=650,
                enable_js=True)     # The profile editor needs JavaScript
        except Exception as exception:
            logging.error(str(exception))
            self.__parent.error_message(_tr('sb_avatar_link_failed'), str(exception))

        self.__parent.clicked_sidebar_button()


    # Open the changelog
    def __clicked_changelog(self, *_):
        try:
            changelog_url = get_changelog_url(self.__settings.language)

            utils.open_webwindow(
                url=utils.expand_variables(changelog_url),
                title=_tr('sb_changelog_window_title'),
                width=1000,
                height=650,
                enable_js=True)     # Markdown is used on the page, need JS
        except Exception as exception:
            logging.error(str(exception))
            self.__parent.error_message(_tr('sb_changelog_link_failed'), str(exception))

        self.__parent.clicked_sidebar_button()


    # Generic sidebar button command handler
    def __clicked_sidebar_button(self, button):
        try:
            command = button.data
            arguments = command.get('args', '')

            # Support plain strings and arrays of strings as arguments
            if isinstance(arguments, list):
                arguments = ' '.join(arguments).strip()

            if not arguments:
                logging.error('Sidebar button without a command!')
                self.__parent.error_message(
                    'Nothing to do',
                    'This button has no commands associated with it.')
                return

            self.__parent.clicked_sidebar_button()

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
                    pass_form_response_to = settings.get('pass_form_response_to', None)

                    if title:
                        title = _tr(title)

                utils.open_webwindow(
                    url=arguments,
                    title=title,
                    width=width,
                    height=height,
                    enable_js=enable_js,
                    pass_form_response_to=pass_form_response_to)
        except Exception as exception:
            logging.error('Could not process a sidebar button click!')
            logging.error(str(exception))
            self.__parent.error_message(_tr('sb_button_failed'), str(exception))


    # --------------------------------------------------------------------------
    # Utility

    # Creates a sidebar button
    def __create_button(self, ypos, data):
        if not 'title' in data or not 'command' in data:
            logging.error('Cannot create a sidebar button (missing title/command):')
            logging.error(data)
            return ypos

        try:
            icon = (self.__icons, self.__icons[data['icon']][0])
        except BaseException as exc:
            logging.error('Unable to load a sidebar button icon: %s', str(exc))
            icon = None

        try:
            button = buttons.sidebar.SidebarButton(
                self,
                self.__settings,
                _tr(data['title']),
                icon,
                _tr(data.get('description', None)),
                data['command'])

            button.connect('clicked', self.__clicked_sidebar_button)
            button.show()
            self.container.put(button, 0, ypos)

            # the next available Y coordinate
            return ypos + button.get_preferred_button_size()[1]
        except BaseException as exc:
            logging.error('Cannot create a sidebar button!')
            logging.error(exc, exc_info=True)
            return ypos


    # Creates a special sidebar separator
    def __create_separator(self, ypos):
        padding = 20

        utils_gui.create_separator(
            container=self.container,
            x=padding,
            y=ypos + MAIN_PADDING,
            w=SIDEBAR_WIDTH - padding * 2,
            h=-1,
            orientation=Gtk.Orientation.HORIZONTAL)

        # the next available Y coordinate
        return ypos + MAIN_PADDING * 2 + SEPARATOR_SIZE
