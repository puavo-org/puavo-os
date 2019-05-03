# Program settings. Determined at startup, then used everywhere. The program
# never *writes* any settings back to disk.

# IMPORTANT NOTICE: Do not import GTK or Cairo or other such modules
# here! This file is used in places where no graphical libraries have
# been used, or even needed.


class Settings:
    def __init__(self):
        # ----------------------------------------------------------------------
        # Configurable from the command line

        # True if we're in production mode. Production mode disables the
        # development mode popup menu, changes some logging-related things,
        # removes the titlebar and prevents the program from exiting, but
        # otherwise the two modes are identical. Production mode is not
        # enabled by default.
        self.prod_mode = False

        # True if window autohide is enabled (usually not used in development
        # mode, but can be enabled in it too if wanted)
        self.autohide = False

        # Directory for the built-in resources (images mostly)
        self.res_dir = ''

        # Directory where menudata and conditionals are loaded from
        self.menu_dir = ''

        # Where user settings are saved (usually ~/.config/puavomenu)
        self.user_dir = ''

        # Language code (en/fi/de/sv)
        self.language = 'en'

        # IPC socket name, for relaying show/hide commands from the
        # panel button. See /opt/puavomenu/send_command.
        self.socket = ''

        # ----------------------------------------------------------------------
        # Automagically detected

        # Location for desktop icon files
        self.desktop_dir = None

        # Is this a guest session?
        self.is_guest = False

        # Is this a webkiosk session?
        self.is_webkiosk = False

        # Is this a fatclient system?
        self.is_fatclient = False

        # True if the global GNOME dark theme is enabled
        self.dark_theme = False

        # True if we will be saving favorites (ie. the most often used
        # programs). Guest and webkiosk sessions disable this.
        self.enable_faves_saving = True

        # ----------------------------------------------------------------------
        # Per-user settings

        # If True, the menu is reset back to the default view after you
        # click a program or a search result. Set to False to retain the
        # current view. Can be configured through the per-user config file.
        self.reset_view_after_start = True

    def detect_environment(self):
        """Detects the runtime-environment for this session. Call once
        at startup."""

        from os import environ
        from os.path import expanduser, join, isfile
        import configparser
        import subprocess

        import logging
        from utils import puavo_conf

        # Detect the session and device types
        if 'GUEST_SESSION' in environ:
            logging.info('This is a guest user session')
            self.is_guest = True

        if puavo_conf('puavo.hosttype', 'laptop') == 'fatclient':
            logging.info('This is a fatclient device')
            self.is_fatclient = True

        if puavo_conf('puavo.webmenu.webkiosk', '') == 'true':
            # I don't know if this actually works!
            logging.info('This is a webkiosk session')
            self.is_webkiosk = True

        if self.is_guest or self.is_webkiosk:
            # No point in saving faves when they get blown away upon logout.
            # No point in loading them, either.
            logging.info('Faves loading/saving is disabled for this session')
            self.enable_faves_saving = False

        # Detect dark theme usage
        try:
            name = join(expanduser('~'),
                        '.config',
                        'gtk-3.0',
                        'settings.ini')

            config = configparser.ConfigParser()
            config.read(name)

            if config.getboolean('Settings',
                                 'gtk-application-prefer-dark-theme',
                                 fallback=False):
                self.dark_theme = True
                logging.info('Dark theme has been enabled')
        except Exception as exception:
            # okay then, no dark theme for you
            logging.error('Dark theme check failed')
            logging.error(str(exception))

        # Load the per-user config file, if it exists
        conf_file = join(self.user_dir, 'puavomenu.conf')

        if isfile(conf_file):
            logging.info('A per-user configuration file "%s" exists, '
                         'trying to load it...', conf_file)

            try:
                config = configparser.ConfigParser()
                config.read(conf_file)

                self.reset_view_after_start = \
                    config.getboolean('puavomenu',
                                      'reset_view_after_start',
                                      fallback=True)
            except Exception as exception:
                logging.error(str(exception))

        # Determine the location of the desktop directory
        try:
            # There are some XDG modules available for Python
            # that probably can do this for us, but right now
            # I don't want to install any more dependencies.
            proc = subprocess.Popen(
                ['xdg-user-dir', 'DESKTOP'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE)

            proc.wait()
            self.desktop_dir = proc.stdout.read().decode('utf-8').strip()
        except Exception as exception:
            # Keep as None to signal that we don't know where to put desktop
            # files, this makes desktop link creation always fail
            logging.error("Could not determine the location of user's "
                          "desktop directory")
            logging.error(str(exception))
            self.desktop_dir = None
