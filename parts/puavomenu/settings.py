# Program settings. Determined at startup, then used everywhere. The program
# never *writes* any settings back to disk.

# IMPORTANT NOTICE: Do not import GTK or Cairo or other such modules in
# this file! This file is used in places where no graphical libraries
# have been used, or even needed.


class Settings:
    def __init__(self):
        # ----------------------------------------------------------------------
        # Configurable from the command line

        # True if we're in production mode. Production mode disables the
        # development mode popup menu, changes some logging-related things,
        # removes the titlebar and prevents the program from exiting, but
        # otherwise the two modes are identical.
        self.prod_mode = False

        # True if window autohide is enabled (usually not used in development
        # mode, but it can be enabled if so desired)
        self.autohide = False

        # Directory for the built-in resources (images mostly)
        self.res_dir = ""

        # Directory where menudata and conditionals are loaded from
        self.menu_dir = ""

        # Where user settings are saved (usually ~/.config/puavomenu)
        self.user_conf = ""

        # The directory where user-defined programs are automatically loaded
        # and updated from. Not always specified.
        self.user_programs_dir = None

        # Language code (en/fi/de/sv/etc.)
        self.language = "en"

        # IPC socket name, for relaying show/hide commands from the
        # panel button. See /opt/puavomenu/send_command.
        self.socket = ""

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

        # Is this device personally administered?
        self.is_personally_administered = False

        # Is the current user the device's primary user? Cannot be True
        # unless 'is_personally_administered' is also True.
        self.is_user_primary_user = False

        # The user's puavo ID
        self.user_puavo_id = -1

        # User type (student, teacher, etc.). Some of the web services
        # that are opened from the menu needs to know this.
        self.user_type = "student"

        # The primary school of the user, or -1 if unknown
        self.user_primary_school = -1

        # True if we will be saving program usage counts. Guest and webkiosk
        # sessions disable this. The frequently used programs list is built
        # from these numbers.
        self.save_usage_counters = True

        # If False, the user programs category will be disabled and hidden
        self.show_user_programs = True

        # ----------------------------------------------------------------------
        # Per-user settings

        # If True, the menu is reset back to the default view after you
        # click a program or a search result. Set to False to retain the
        # current view. Can be configured through the per-user config file.
        self.reset_view_after_start = True

        # If true, the menus and programs will be sorted alphabetically at
        # load-time, ignoring the original order.
        self.sort_contents_alphabetically = False

    def detect_environment(self):
        """Detects the runtime-environment for this session. Call once
        at startup."""

        import os
        import os.path
        import configparser
        import subprocess
        import logging
        import json
        import utils

        # Detect the session and device types
        if "GUEST_SESSION" in os.environ:
            logging.info("detect_environment(): this is a guest user session")
            self.is_guest = True

        if utils.puavo_conf("puavo.hosttype", "laptop") == "fatclient":
            logging.info("detect_environment(): this is a fatclient device")
            self.is_fatclient = True

        if utils.puavo_conf("puavo.webmenu.webkiosk", "") == "true":
            # I don't know if this actually works!
            logging.info("detect_environment(): this is a webkiosk session")
            self.is_webkiosk = True

        if self.is_guest or self.is_webkiosk:
            # No point in saving frequently-used programs when they get blown
            # away upon logout. No point in loading them, either.
            logging.info(
                "detect_environment(): program usage counter loading/saving "
                "is disabled for this session"
            )
            self.save_usage_counters = False

        if utils.puavo_conf("puavo.admin.personally_administered", "false") == "true":
            self.is_personally_administered = True

            try:
                import pwd

                configured_primary_user = utils.puavo_conf(
                    "puavo.admin.primary_user", None
                )
                current_user = pwd.getpwuid(os.getuid()).pw_name

                if configured_primary_user == current_user:
                    # The current user is this personally administered
                    # device's configured primary user
                    self.is_user_primary_user = True
            except Exception as e:
                logging.error(
                    "detect_environment(): cannot determine if the "
                    "current user is this device's configured primary user:"
                )
                logging.error(str(e))

        # Load the user type and primary school from the session data generated during login
        try:
            if "PUAVO_SESSION_PATH" in os.environ:
                VALID_TYPES = frozenset(
                    ("student", "teacher", "admin", "staff", "visitor", "guest")
                )

                with open(
                    os.path.expandvars("$PUAVO_SESSION_PATH"),
                    mode="r",
                    encoding="utf-8",
                ) as session:
                    session_data = json.load(session)

                self.user_puavo_id = session_data["user"]["id"]
                self.user_type = session_data["user"]["user_type"]

                if self.user_type not in VALID_TYPES:
                    logging.warning(
                        'detect_environment(): unknown user type "%s", '
                        'defaulting to "student"',
                        self.user_type,
                    )
                    self.user_type = "student"

                self.user_primary_school = session_data["user"]["primary_school_id"]
            else:
                logging.warning(
                    'detect_environment(): "PUAVO_SESSION_PATH" not in environment '
                    'variables, user type cannot be determined, assuming "student"'
                )
                self.user_type = "student"
        except Exception as e:
            logging.error(
                'detect_environment(): cannot determine user type, assuming "student":'
            )
            logging.error(str(e))
            self.user_type = "student"
            self.user_primary_school = -1

        # Load the per-user config file, if it exists
        if not (self.is_guest or self.is_webkiosk):
            conf_file = os.path.join(self.user_conf, "puavomenu.conf")

            if os.path.isfile(conf_file):
                logging.info(
                    'detect_environment(): a per-user configuration file "%s" exists, '
                    "trying to load it...",
                    conf_file,
                )

                try:
                    config = configparser.ConfigParser()
                    config.read(conf_file)

                    self.reset_view_after_start = config.getboolean(
                        "puavomenu", "reset_view_after_start", fallback=True
                    )

                    self.sort_contents_alphabetically = config.getboolean(
                        "puavomenu", "sort_contents_alphabetically", fallback=False
                    )

                except Exception as exception:
                    logging.error(
                        'detect_environment(): failed to load file "%s":', conf_file
                    )
                    logging.error(str(exception))

        # Determine the location of the desktop directory
        try:
            # There are some XDG modules available for Python
            # that probably can do this for us, but right now
            # I don't want to install any more dependencies.
            proc = subprocess.Popen(
                ["xdg-user-dir", "DESKTOP"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            proc.wait()
            self.desktop_dir = proc.stdout.read().decode("utf-8").strip()
        except Exception as exception:
            # Keep as None to signal that we don't know where to put desktop
            # files, this makes desktop link creation always fail
            logging.error(
                "detect_environment(): could not determine the "
                "location of the user's desktop directory:"
            )
            logging.error(str(exception))
            self.desktop_dir = None
