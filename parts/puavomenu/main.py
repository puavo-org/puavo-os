# PuavoMenu main. Creates and sets up the window and the user interface,
# loads menu data, and handles all menu navigation and program/menu
# button clicks.

import time
import os
import os.path
import logging
import traceback
import syslog
import json
import subprocess

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import Pango
from gi.repository import GLib
from gi.repository import Gio

from constants import *

import utils
import utils_gui

import filters.conditionals
import filters.tags

import menudata
import icons
import loaders.json_loader
import loaders.menudata_loader
import puavopkg
import user_programs

import buttons.program, buttons.menu
import frequent_programs
from sidebar import sidebar

from strings import STRINGS


class PuavoMenu(Gtk.Window):
    def error_message(self, message, secondary_message=None):
        """Show a modal error message box."""

        dialog = Gtk.MessageDialog(
            parent=self,
            modal=True,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=message
        )

        if secondary_message:
            dialog.format_secondary_markup(secondary_message)

        self.disable_out_of_focus_hide()
        dialog.run()
        dialog.hide()
        self.enable_out_of_focus_hide()


    def __init__(self, settings, socket, program_start_time):
        start_time = time.perf_counter()

        super().__init__(name='root')       # CSS ID

        self.__settings = settings
        self.__socket = socket

        # ----------------------------------------------------------------------
        # Setup the window

        # Ensure the window is not visible until it's ready
        self.set_visible(False)

        # Set window style
        if self.__settings.prod_mode:
            self.set_type_hint(Gdk.WindowTypeHint.MENU)
            self.set_skip_taskbar_hint(True)
            self.set_skip_pager_hint(True)
            self.set_deletable(False)       # no close button
            self.set_decorated(False)
            self.__exit_permitted = False
        else:
            # makes developing slightly easier
            self.set_skip_taskbar_hint(False)
            self.set_skip_pager_hint(False)
            self.set_deletable(True)
            self.set_decorated(True)
            self.__exit_permitted = True

        self.set_resizable(False)
        self.set_size_request(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_gravity(Gdk.Gravity.SOUTH_WEST)

        # Don't mess with the real menu when running in development mode
        if self.__settings.prod_mode:
            self.set_title('PuavoMenuUniqueName')
        else:
            self.set_title('DevPuavomenu')

        # Enable transparent window magic. I'm not entirely sure what
        # this does, but it works.
        self.set_visual(self.get_screen().get_rgba_visual())

        # Setup custom CSS
        css_file = os.path.join(self.__settings.res_dir, 'puavomenu.css')

        if os.path.isfile(css_file):
            logging.info('CSS file "%s" exists, loading it', css_file)

            css = bytes(utils.get_file_contents(css_file, ''), 'utf-8')

            style_provider = Gtk.CssProvider()
            style_provider.load_from_data(css)

            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                style_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

        # Create the devtools popup menu
        if not self.__settings.prod_mode:
            self.menu_signal = self.connect('button-press-event', self.__devtools_menu)

        self.connect('delete-event', self.__try_exit)

        # ----------------------------------------------------------------------
        # Menu data

        # Program, menu and category data (an instance of menudata.Menudata)
        self.menudata = None

        # Current category (index to menudata.category_index)
        self.current_category = -1

        # The current menu (None if on category top-level)
        self.current_menu = None

        # The current menu/program buttons in the current
        # category and menu
        self.__buttons = []

        # Storage for 48x48 -pixel program and menu icons. Maintained
        # separately from the menu data.
        self.__icons = icons.IconCache(1024, 48)

        # General-purpose "icon locator" system. Figuring out which icon
        # files to actually load is complicated.
        self.__icon_locator = icons.IconLocator(icon_dirs=[])

        # Is the first update on user programs done?
        self.__user_programs_loaded = False

        # Contents of dirs.json
        self.__dirs_config = menudata.DirsConfig()

        # ----------------------------------------------------------------------
        # Start creating the UI. Menus/programs list first.

        # Main menu container
        self.menu_fixed = Gtk.Fixed()

        # TODO: Gtk.Notebook isn't the best choice for this

        # Category tabs
        self.__category_buttons = Gtk.Notebook(name='category')
        self.__category_buttons.set_size_request(CATEGORIES_WIDTH, -1)
        self.__category_buttons.set_scrollable(True)
        self.__category_buttons.connect('switch-page', self.__clicked_category)
        self.menu_fixed.put(self.__category_buttons, 0, 0)

        # The back button
        self.__back_button = Gtk.Button()
        self.__back_button.set_label('<<')
        self.__back_button.connect('clicked', self.__clicked_back_button)
        self.__back_button.set_size_request(BACK_BUTTON_WIDTH, 30)
        self.menu_fixed.put(self.__back_button, 0, BACK_BUTTON_Y)

        # Menu label and description
        self.__menu_title = Gtk.Label(name='menu_title')
        self.__menu_title.set_size_request(375, -1)
        self.__menu_title.set_ellipsize(Pango.EllipsizeMode.END)
        self.__menu_title.set_justify(Gtk.Justification.CENTER)
        self.__menu_title.set_xalign(0.0)
        self.__menu_title.set_yalign(0.5)
        self.__menu_title.set_use_markup(True)

        self.menu_fixed.put(
            self.__menu_title,
            BACK_BUTTON_WIDTH + MAIN_PADDING,
            BACK_BUTTON_Y + 5)

        # The search box
        self.__search = Gtk.SearchEntry()
        self.__search.set_size_request(SEARCH_WIDTH, -1)
        self.__search.set_max_length(10)    # you aren't going need more than this

        self.__search_changed_signal = \
            self.__search.connect('changed', self.__do_search)

        self.__search_keypress_signal = \
            self.__search.connect('key-press-event', self.__search_keypress)

        self.__search.set_placeholder_text(
            utils.localize(STRINGS['search_placeholder'], self.__settings.language))

        self.menu_fixed.put(self.__search, PROGRAMS_WIDTH - (SEARCH_WIDTH + 10) - 9, 40)

        # Filter unwanted characters from searches. Searching is done using
        # regexps and these character cause problems. You can type these
        # characters in the search box, but they're removed from the string
        # before searching is done.
        # TODO: Prevent, don't filter. Use some callback method to filter
        # the characters the user is typing.
        self.__translation_table = \
            dict.fromkeys(map(ord, "*^?{[]}/\\_+=\"\'#%&()'`@$<>|~"),
                          None)

        # The main programs list
        self.__programs_container = Gtk.ScrolledWindow(name='programs')
        self.__programs_container.set_size_request(PROGRAMS_WIDTH,
                                                   PROGRAMS_HEIGHT)
        self.__programs_container.set_policy(Gtk.PolicyType.NEVER,
                                             Gtk.PolicyType.AUTOMATIC)
        self.__programs_container.set_shadow_type(Gtk.ShadowType.NONE)

        # Program icons. They're placed on a fixed grid, as their positions
        # can be computed exactly and are known in advance.
        self.__programs_icons = Gtk.Fixed()
        self.__programs_container.add_with_viewport(self.__programs_icons)

        self.menu_fixed.put(self.__programs_container, 0, PROGRAMS_TOP)

        # Placeholder message for empty categories, menus and search results
        self.__empty = Gtk.Label(name='empty')
        self.__empty.set_size_request(PROGRAMS_WIDTH, PROGRAMS_HEIGHT)
        self.__empty.set_justify(Gtk.Justification.CENTER)
        self.__empty.set_xalign(0.5)
        self.__empty.set_yalign(0.5)
        self.menu_fixed.put(self.__empty, 0, PROGRAMS_TOP)

        # Keep track of most frequently used programs
        self.__program_launch_counts = frequent_programs.ProgramLaunchesCounter(
            self.__settings.user_conf,
            self.__settings.save_usage_counters
        )

        self.__frequent_sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        self.__frequent_sep.set_size_request(PROGRAMS_WIDTH, 1)

        self.menu_fixed.put(self.__frequent_sep,
                            0,
                            PROGRAMS_TOP + PROGRAMS_HEIGHT + MAIN_PADDING)

        self.__frequent_list = \
            frequent_programs.FrequentProgramsList(self)

        self.__frequent_list.set_size_request(PROGRAMS_WIDTH, PROGRAM_BUTTON_HEIGHT)

        self.menu_fixed.put(self.__frequent_list, 0, FREQUENT_TOP)

        self.menu_fixed.show()

        # Main menu container
        self.menu_box = Gtk.Box(name='menubox')
        self.menu_box.pack_start(self.menu_fixed, False, False, 0)
        self.menu_box.show()

        # ----------------------------------------------------------------------
        # The sidebar: the user avatar, buttons, host infos

        self.__sidebar = sidebar.Sidebar(self, self.__settings)

        # Main sidebar container
        self.sidebar_box = Gtk.Box(name='sidebar')
        self.sidebar_box.pack_start(self.__sidebar.container, False, False, 0)
        self.sidebar_box.show()

        # ----------------------------------------------------------------------
        # Setup GTK signal handlers

        # Listen for Esc keypresses for manually hiding the window
        self.__main_keypress_signal = \
            self.connect('key-press-event', self.__check_for_esc)

        self.__focus_signal = None

        if not self.__settings.autohide:
            # Keep the window on top of everything and show it
            self.set_visible(True)
            self.set_keep_above(True)
        else:
            # In auto-hide mode, hide the window when it loses focus
            self.enable_out_of_focus_hide()

        self.__search.connect('focus-out-event', self.__search_out)

        # ----------------------------------------------------------------------
        # Final UI assembly

        # Fixed containers cannot be styled with CSS, but Box containers can.
        # So create a fixed container for the whole window (the window can
        # only contain one child anyway, so we always need some container).
        # Then put two Box containers in it and cram the fixed-sized child
        # containers inside them. The main window isn't resizable, so while
        # this is a bit convoluted, it works and makes the program fully
        # styleable with CSS.
        self.__main_container = Gtk.Fixed()
        self.__main_container.set_size_request(WINDOW_WIDTH, WINDOW_HEIGHT)

        self.__main_container.put(self.menu_box, MAIN_PADDING, MAIN_PADDING)

        self.__main_container.put(self.sidebar_box, SIDEBAR_LEFT, SIDEBAR_TOP)

        self.add(self.__main_container)
        self.__main_container.show()

        # DO NOT CALL self.show_all() HERE, the window has hidden elements
        # that are shown/hidden on demand. And we don't even have any
        # menu data yet to show.

        # ----------------------------------------------------------------------
        # Start listening the IPC socket

        # Use glib's watch functions, then we don't need to use threads
        # (which work too, but are harder to clean up and we'll run into
        # problems with multihtreaded xlib programs).
        # https://developer.gnome.org/pygobject/stable/glib-functions.html#
        #   function-glib--io-add-watch

        GLib.io_add_watch(self.__socket, GLib.IO_IN, self.__socket_accept)

        win_init_time = time.perf_counter()
        utils.log_elapsed_time('Window init time', start_time, win_init_time)

        # ----------------------------------------------------------------------
        # Load menu data

        self.load_menu_data()

        # This is a bad, bad situation that should never happen in production.
        # It will happen one day.
        if not self.menudata or not self.menudata.programs:
            if self.__settings.prod_mode:
                self.__show_empty_message(STRINGS['menu_no_data_at_all_prod'])
            else:
                self.__show_empty_message(STRINGS['menu_no_data_at_all_dev'])

        # ----------------------------------------------------------------------

        end_time = time.perf_counter()
        utils.log_elapsed_time('Time from program start to usable state',
                               program_start_time, end_time)


    # --------------------------------------------------------------------------
    # Menu data loading and handling


    # Loads menu data and sets up the UI. Returns false if
    # something fails.
    def load_menu_data(self):
        logging.info('PuavoMenu::load_menu_data() starts')

        try:
            total_start_time = time.perf_counter()
            start_time = total_start_time

            # A list of puavo-pkg programs that are NOT part of the desktop
            # image BUT can be installed/uninstalled dynamically
            dynamic_puavopkg_ids = utils.puavo_conf('puavo.pkgs.ui.pkglist', '')

            puavopkg_states = puavopkg.detect_package_states(dynamic_puavopkg_ids)

            end_time = time.perf_counter()
            utils.log_elapsed_time('puavopkg state detection', start_time, end_time)

            # ------------------------------------------------------------------
            # Load dirs.json

            dirs_file = os.path.join(self.__settings.menu_dir, 'dirs.json')
            logging.info('Loading directory configuration file "%s"', dirs_file)

            try:
                with open(dirs_file, 'r', encoding='utf-8') as df:
                    dirs = json.load(df)

                self.__dirs_config.desktop_dirs = dirs.get('desktop_dirs', [])
                icon_dirs = dirs.get('icon_dirs', {})
                self.__dirs_config.theme_icon_dirs = icon_dirs.get('themes', {})
                self.__dirs_config.generic_icon_dirs = icon_dirs.get('generic', [])
            except BaseException as exc:
                logging.fatal('Failed to load the directories config file "%s"',
                              dirs_file)
                logging.fatal(exc, exc_info=True)
                self.__dirs_config.clear()

            icon_dirs = []

            # Figure out the current icon theme name and prioritize it
            # when loading icons
            try:
                gsettings = Gio.Settings.new('org.gnome.desktop.interface')
                icon_theme = gsettings.get_value('icon-theme').get_string()
            except BaseException as e:
                logging.warning("Could not determine the name of the current icon theme: %s",
                                str(e))
                icon_theme = None

            logging.info('Current icon theme name: "%s"', icon_theme)

            if icon_theme and icon_theme in self.__dirs_config.theme_icon_dirs:
                icon_dirs += self.__dirs_config.theme_icon_dirs[icon_theme]

            icon_dirs += self.__dirs_config.generic_icon_dirs

            # Icons for user programs
            for name in icons.get_user_icon_dirs():
                icon_dirs.append(name[1])

            self.__icon_locator.set_directories(icon_dirs)
            self.__icon_locator.clear_cache()

            # ------------------------------------------------------------------
            # Load and evaluate conditionals

            start_time = time.perf_counter()

            raw_conditional_files = loaders.menudata_loader.find_menu_files(
                os.path.join(self.__settings.menu_dir, 'conditions'))

            conditional_files = loaders.menudata_loader.sort_menu_files(
                raw_conditional_files)

            raw_conditionals = {}

            for name in conditional_files:
                logging.info('Loading conditional file "%s"', name)

                try:
                    with open(name, 'r', encoding='utf-8') as f:
                        contents = f.read()

                        if not contents:
                            # empty strings are invalid JSON,
                            # so manually "fix" empty files
                            contents = '{}'

                        data = json.loads(contents)
                except BaseException as e:
                    logging.error("Can't load conditionals file \"%s\":", name)
                    logging.error(e, exc_info=True)
                    continue

                conds = filters.conditionals.load(data)

                if conds:
                    raw_conditionals.update(conds)

            conditionals = filters.conditionals.evaluate(raw_conditionals)

            end_time = time.perf_counter()
            utils.log_elapsed_time('Conditionals load time', start_time, end_time)

            # ------------------------------------------------------------------
            # Load filters

            start_time = time.perf_counter()

            tags = filters.tags.Filter(utils.puavo_conf('puavo.puavomenu.tags', ''))

            end_time = time.perf_counter()

            utils.log_elapsed_time('Tag filter parsing time', start_time, end_time)

            # Manually check the visibility of the user programs category.
            # (The category is created manually, so menudata checks don't
            # work with it.)
            if tags.has_action_for(filters.tags.Action.HIDE,
                                   filters.tags.Action.CATEGORY,
                                   'category-user-programs'):
                logging.info('The user programs category has been explicitly hidden/disabled')
                self.__settings.show_user_programs = False

            # ------------------------------------------------------------------
            # Locate menudata files and load them

            start_time = time.perf_counter()

            raw_menu_files = loaders.menudata_loader.find_menu_files(
                os.path.join(self.__settings.menu_dir, 'menudata'))

            menudata_files = loaders.menudata_loader.sort_menu_files(raw_menu_files)

            end_time = time.perf_counter()
            utils.log_elapsed_time('Time to locate available menu data', start_time, end_time)

            self.menudata = loaders.menudata_loader.load(
                menudata_files, self.__settings.language,
                self.__dirs_config.desktop_dirs,
                tags, conditionals,
                puavopkg_states,
                self.__icon_locator,
                self.__icons)

            # (Re)load user programs
            if self.__settings.show_user_programs:
                if not (self.__settings.is_guest or self.__settings.is_webkiosk):
                    self.__setup_user_programs()

            total_end_time = time.perf_counter()
            utils.log_elapsed_time('Total load time',
                                   total_start_time, total_end_time)

            cache_stats = self.__icons.stats()

            logging.info('Cached %d 48x48-pixel icons in %d atlases',
                         cache_stats['num_icons'], cache_stats['num_atlases'])

        except Exception as exception:
            logging.fatal('Could not load menu data!')
            logging.error(exception, exc_info=True)

            if self.__settings.prod_mode:
                syslog.syslog(syslog.LOG_CRIT, 'Could not load menu data!')
                syslog.syslog(syslog.LOG_CRIT, traceback.format_exc())

            self.menudata = None
            return False

        # We got this far, so we have at least some menu data.
        # Prepare the user interface.
        for index in self.menudata.category_index:
            cat = self.menudata.categories[index]

            frame = Gtk.Frame()
            label = Gtk.Label(cat.name)
            frame.show()
            label.show()
            self.__category_buttons.append_page(frame, label)

        if self.menudata.category_index:
            self.__category_buttons.show()

        self.__create_current_menu()
        self.__programs_container.show()

        if self.menudata.category_index:
            self.__program_launch_counts.load()
            self.__update_frequent_programs_list()
            self.__frequent_sep.show()
            self.__frequent_list.show()
            self.__search.show()
            self.__search.grab_focus()

        logging.info('PuavoMenu::load_menu_data() ends')
        return True


    # Completely removes all menu data. Hides everything programs-related
    # from the UI.
    def unload_menu_data(self):
        self.__category_buttons.hide()

        while self.__category_buttons.get_n_pages():
            self.__category_buttons.remove_page(-1)

        self.__search.hide()
        self.__clear_search_field()

        self.__empty.hide()
        self.__back_button.hide()
        self.__menu_title.hide()
        self.__programs_icons.hide()
        self.__programs_container.hide()

        for button in self.__buttons:
            button.destroy()

        self.__buttons = []

        self.__frequent_sep.hide()
        self.__frequent_list.hide()
        self.__frequent_list.clear()

        self.menudata = None
        self.current_category = -1
        self.current_menu = None

        self.__user_programs_loaded = False
        self.__dirs_config.clear()
        self.__icons.clear()


    def __update_frequent_programs_list(self, force=False):
        # programs sorted by their launch counts
        all_ids = self.__program_launch_counts.get_frequent_programs()

        # weed out programs that don't exist (don't REMOVE them,
        # just don't show them)
        usable_ids = []

        for _, pid in all_ids:
            if pid in self.menudata.programs:
                usable_ids.append(pid)

        # only show the N most often used programs
        usable_ids = usable_ids[0:PROGRAMS_PER_ROW]

        self.__frequent_list.update(
            usable_ids,
            self.menudata.programs, self.__settings, self.__icons,
            force)


    # --------------------------------------------------------------------------
    # User programs handling


    # Rebuilds the category list. Called when user programs are
    # live-reloaded.
    def __rebuild_category_list(self):
        self.__category_buttons.hide()

        while self.__category_buttons.get_n_pages():
            self.__category_buttons.remove_page(-1)

        for index in self.menudata.category_index:
            cat = self.menudata.categories[index]

            frame = Gtk.Frame()
            label = Gtk.Label(cat.name)
            frame.show()
            label.show()
            self.__category_buttons.append_page(frame, label)

        self.__category_buttons.set_current_page(self.current_category)
        self.__category_buttons.show()


    # Creates and appends the user category at the end of the categories list
    def __create_user_category(self, category):
        category.menudata_id = 'category-user-programs'
        category.name = utils.localize(STRINGS['user_category'], self.__settings.language)
        category.position = 999999
        category.flags |= menudata.CategoryFlags.USER_CATEGORY
        self.menudata.categories[category.menudata_id] = category
        self.menudata.category_index.append(category.menudata_id)


    # Initial scan for user programs
    def __setup_user_programs(self):
        if not self.__settings.show_user_programs:
            return

        temp_category = menudata.Category()

        if user_programs.update(self.__settings.user_progs,
                                self.menudata.programs,
                                temp_category,
                                self.__icon_locator,
                                self.__icons,
                                self.__settings.language):
            # We got user programs! Manually create a new category for
            # them and tuck it at the end of the categories list
            self.__create_user_category(temp_category)

        # Permit live reloading of user programs
        self.__user_programs_loaded = True


    # Recreates the current menu view if it's in user programs.
    # Call if user programs have changed since the last update.
    def __update_user_category_view(self):
        if not self.__settings.show_user_programs:
            return

        # Are we in search mode or normal menu view?
        if self.__get_search_text():
            # __do_search() is a callback, we must pass in a widget,
            # but it's not used for anything so None will do
            self.__do_search(None)
            return

        if not self.menudata.category_index:
            # No categories at all (this is an error)
            return

        if self.current_menu is not None:
            # We're in a menu, not category view
            return

        if self.current_category > len(self.menudata.category_index) - 1:
            # Invalid category index
            return

        cat = self.menudata.categories[self.menudata.category_index[self.current_category]]

        if not cat.flags & menudata.CategoryFlags.USER_CATEGORY:
            # Not a user category
            return

        # The user category view is open, so we must do a live update
        self.__create_current_menu()


    # --------------------------------------------------------------------------
    # Menu view handling


    def __make_program_button(self, program):
        return buttons.program.ProgramButton(
            parent=self,
            settings=self.__settings,
            label=program.name,
            icon=(self.__icons, program.icon),
            tooltip=program.description,
            data=program)


    def __make_menu_button(self, menu):
        return buttons.menu.MenuButton(
            parent=self,
            settings=self.__settings,
            label=menu.name,
            icon=(self.__icons, menu.icon),
            tooltip=menu.description,
            data=menu)


    # Returns True if puavo-pkg installer icons should be hidden
    # in this session
    def __are_installers_hidden(self):
        if not self.__settings.is_user_primary_user:
            return True

        if self.__settings.is_guest:
            return True

        if self.__settings.is_fatclient:
            return True

        return False


    # Shows an "empty" message in the main programs list. Used when a
    # menu/category is empty, or there are no search results.
    def __show_empty_message(self, msg):
        if isinstance(msg, dict):
            msg = utils.localize(msg, self.__settings.language)

        self.__empty.set_label(msg)
        self.__empty.show()


    # Replaces the existing menu and program buttons with new buttons
    # in the icons container widget
    def __place_buttons_in_container(self, new_buttons):
        self.__programs_icons.hide()
        self.__programs_container.hide()

        # Remove the old buttons first
        for button in self.__buttons:
            button.destroy()

        self.__buttons = []

        # Insert the new buttons and arrange them in rows and columns
        xpos = 0
        ypos = 0

        for index, button in enumerate(new_buttons):
            self.__programs_icons.put(button, xpos, ypos)
            self.__buttons.append(button)

            xpos += PROGRAM_BUTTON_WIDTH + PROGRAM_COL_PADDING

            if (index + 1) % PROGRAMS_PER_ROW == 0:
                xpos = 0
                ypos += PROGRAM_BUTTON_HEIGHT + PROGRAM_ROW_PADDING

        self.__programs_icons.show_all()

        if self.__buttons:
            self.__programs_icons.show()
            self.__programs_container.show()


    def __update_menu_title(self):
        if self.current_menu:
            self.__menu_title.set_markup(
                '<big>{0}</big>'.format(self.current_menu.name))
            self.__menu_title.show()
            self.__back_button.show()
        else:
            self.__menu_title.hide()
            self.__back_button.hide()


    # (Re-)Creates the current category or menu view
    def __create_current_menu(self):
        if self.menudata is None:
            self.__programs_icons.hide()
            return

        self.__empty.hide()

        new_buttons = []

        hide_installers = self.__are_installers_hidden()

        if self.current_menu is None:
            # Top-level category view
            if self.menudata.category_index and \
               self.current_category < len(self.menudata.category_index):

                # We have a valid category
                cat = self.menudata.categories[
                    self.menudata.category_index[self.current_category]]

                # Menus first...
                for menu_id in cat.menu_ids:
                    menu = self.menudata.menus[menu_id]

                    button = self.__make_menu_button(menu)
                    button.connect('clicked', self.__clicked_menu_button)
                    new_buttons.append(button)

                # ...then programs
                for prog_id in cat.program_ids:
                    program = self.menudata.programs[prog_id]

                    if hide_installers and \
                        isinstance(program, menudata.PuavoPkgProgram) and \
                        program.is_installer():
                        continue

                    button = self.__make_program_button(program)
                    button.connect('clicked', self.clicked_program_button)
                    new_buttons.append(button)

            # Handle special situations
            if not new_buttons:
                self.__show_empty_message(STRINGS['menu_empty_category'])

        else:
            # Submenu view, have only programs (submenus not needed yet)
            for prog_id in self.current_menu.program_ids:
                program = self.menudata.programs[prog_id]

                if hide_installers and \
                    isinstance(program, menudata.PuavoPkgProgram) and \
                    program.is_installer():
                    continue

                button = self.__make_program_button(program)
                button.connect('clicked', self.clicked_program_button)
                new_buttons.append(button)

            # Handle special situations
            if not self.current_menu.program_ids:
                self.__show_empty_message(STRINGS['menu_empty_menu'])

        self.__place_buttons_in_container(new_buttons)
        self.__update_menu_title()


    # --------------------------------------------------------------------------
    # Menu/category view navigation (button click handlers)


    # Change the category
    def __clicked_category(self, widget, frame, num):
        self.__clear_search_field()
        self.__back_button.hide()
        self.current_category = num
        self.current_menu = None
        self.__create_current_menu()


    # Go back to top level
    def __clicked_back_button(self, button):
        self.__clear_search_field()
        self.__back_button.hide()
        self.current_menu = None
        self.__create_current_menu()


    # Enter a menu
    def __clicked_menu_button(self, button):
        self.__clear_search_field()
        self.__back_button.show()
        self.current_menu = button.data
        self.__create_current_menu()


    # Resets the menu back to the default view
    def reset_view(self):
        self.__clear_search_field()
        self.__back_button.hide()
        self.current_category = 0
        self.current_menu = None
        self.__create_current_menu()
        self.__category_buttons.set_current_page(0)


    # --------------------------------------------------------------------------
    # Program and menu button click handlers


    # Launch a normal program
    def __launch_program(self, program):
        logging.info('Clicked program button "%s"', program.menudata_id)

        # Run a command or open a website?
        if isinstance(program, menudata.Program):
            command = program.command
        else:
            command = program.url

        if command is None:
            logging.error('No command/URL defined for program "%s"', program.name)
            return False

        # Try to launch the program. Use Gio's services, as Gio understands the
        # "Exec=" keys and we don't have to spawn shells with pipes and "sh".
        try:
            if self.__settings.prod_mode:
                # Spy the user and log what programs they use. This information
                # is then sent to various TLAs around the world and used in all
                # sorts of nefarious classified black operations.
                syslog.syslog(syslog.LOG_INFO, 'Launching program "{0}", command="{1}"'.
                              format(program.menudata_id, command))

                # Just kidding. The reason program starts are logged to syslog
                # is actually really simple: you can grep the log and count
                # which programs are actually used and how many times.

                # Of course this only logs programs that are started through
                # Puavomenu, but we decided to ignore this for now.

            logging.info('Executing command/URL "%s"', command)

            if isinstance(program, menudata.Program):
                # Set the program name to empty string ('') to force some (KDE)
                # programs to use their default window titles. These programs
                # have command-line parameters like "-qwindowtitle" or "-caption"
                # and Gio, when launching the program, sets the "%c" argument
                # (in the Exec= key) to the program's name it takes from the
                # command (program.command). This is Wrong(TM), but during
                # testing I noticed that if we leave it empty (*NOT* None
                # because that triggers the unwanted behavior!) then these
                # programs will use their own default titles.
                Gio.AppInfo.create_from_commandline(command, '', 0).launch()
            else:
                # The "command" is a URL for weblinks
                Gio.AppInfo.launch_default_for_uri(command, None)

            # Of course, we never check the return value here, so we
            # don't know if the command actually worked...

            self.autohide()

            if self.__settings.reset_view_after_start:
                # Go back to the default view
                self.reset_view()

        except Exception as exception:
            logging.error('Could not launch program "%s":', program.command)
            logging.error(exception, exc_info=True)

            self.error_message(
                utils.localize(STRINGS['program_launching_failed'], self.__settings.language),
                str(exception))
            return False

        return True


    # Launch a program. This is a public method, it is called from other
    # files (buttons) to launch programs.
    def clicked_program_button(self, button):
        program = button.data

        if isinstance(program, menudata.PuavoPkgProgram) and program.is_installer():
            # This puavo-pkg program has not been installed yet.
            # Launch puavo-pkgs-ui instead.
            logging.info('Launching puavo-pkgs-ui for program "%s", package ID "%s"',
                         program.name, program.package_id)

            self.autohide()

            if self.__settings.reset_view_after_start:
                # Go back to the default view
                self.reset_view()

            # Fill in the --id param so puavo-pkgs-ui can do something with it
            subprocess.Popen(['puavo-pkgs-ui', '--id', program.menudata_id],
                             stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
        else:
            self.__program_launch_counts.increment(program.menudata_id)
            self.__launch_program(program)
            self.__update_frequent_programs_list()

        return True


    # Launch a user-defined program. No puavo-pkg installers here and
    # no usage counting either.
    def clicked_user_program_button(self, button):
        program = button.data
        self.__program_launch_counts.increment(program.menudata_id)
        self.__launch_program(program)
        self.__update_frequent_programs_list()
        return True


    # Called directly from ProgramButton
    def add_program_to_desktop(self, program):
        """Creates a desktop shortcut to a program."""

        if not self.__settings.desktop_dir:
            return

        if isinstance(program, menudata.PuavoPkgProgram) and program.is_installer():
            # Nope. Install it first.
            return

        # Create the link file
        # TODO: use the *original* .desktop file if it exists
        name = os.path.join(self.__settings.desktop_dir, '{0}.desktop'.format(program.name))

        logging.info('Adding program "%s" to the desktop, destination="%s"',
                     program.name, name)

        try:
            utils_gui.create_desktop_link(name, program)
        except Exception as exception:
            logging.error('Desktop link creation failed:')
            logging.error(str(exception))

            self.error_message(
                utils.localize(STRINGS['desktop_link_failed'], self.__settings.language),
                str(exception))


    # Called directly from ProgramButton
    def add_program_to_panel(self, program):
        if isinstance(program, menudata.PuavoPkgProgram) and program.is_installer():
            # Nuh-uh
            return

        logging.info('Adding program "%s" (id="%s") to the bottom panel',
                     program.name, program.menudata_id)

        try:
            utils_gui.create_panel_link(program)
        except Exception as exception:
            logging.error('Panel icon creation failed')
            logging.error(str(exception))

            self.error_message(
                utils.localize(STRINGS['panel_link_failed'], self.__settings.language),
                str(exception))


    # Called directly from ProgramButton
    def remove_program_from_faves(self, p):
        logging.info('Removing "%s" from the frequently-used programs', p.name)
        self.__program_launch_counts.remove(p.menudata_id)
        self.__update_frequent_programs_list()


    # --------------------------------------------------------------------------
    # Searching


    # Returns the current search term, filtered and cleaned
    def __get_search_text(self):
        return self.__search.get_text().strip().translate(self.__translation_table)


    # Searches the programs list using a string, then replaces the menu list
    # with results
    def __do_search(self, _):
        if self.menudata is None:
            return

        key = self.__get_search_text()

        if not key:
            self.__create_current_menu()
            return

        matches = self.menudata.search(key)

        if matches:
            self.__empty.hide()
        else:
            self.__show_empty_message(STRINGS['search_no_results'])

        # create new buttons for results and show them
        new_buttons = []

        for m in matches:
            b = self.__make_program_button(m)
            b.connect('clicked', self.clicked_program_button)
            new_buttons.append(b)

        self.__place_buttons_in_container(new_buttons)


    # Clear the search box without triggering another search
    def __clear_search_field(self):
        self.__search.disconnect(self.__search_keypress_signal)
        self.__search.disconnect(self.__search_changed_signal)
        self.__search.set_text('')
        self.__search_keypress_signal = \
            self.__search.connect('key-press-event', self.__search_keypress)
        self.__search_changed_signal = \
            self.__search.connect('changed', self.__do_search)


    # Responds to Esc and Enter keypresses in the search field
    def __search_keypress(self, widget, key_event):
        self.__back_button.hide()
        self.__menu_title.hide()

        if key_event.keyval == Gdk.KEY_Escape:
            if not self.__get_search_text():
                # Cancel an ongoing search (go back to previous view)
                self.__clear_search_field()
                self.__create_current_menu()
            else:
                # The search field is empty, hide the window (we have
                # another Esc handler elsewhere that's used when the
                # search box has no focus)
                logging.debug('Search field is empty and Esc pressed, '
                              'hiding the window')
                self.autohide()
        elif key_event.keyval == Gdk.KEY_Return:
            if self.__get_search_text() and len(self.__buttons) == 1:
                # There's only one search match and the user pressed
                # Enter, so launch it!
                self.clicked_program_button(self.__buttons[0])
                #self.__clear_search_field()
                #self.__create_current_menu()

        return False


    # Handler for the GTK focus-out-event in the search box.
    # Put the focus back in the search box.
    def __search_out(self, *unused):
        self.__search.grab_focus()


    # --------------------------------------------------------------------------
    # Window visibility management


    # Hides the window if Esc is pressed when the keyboard focus
    # is not in the search box (the search box has its own Esc
    # handler).
    def __check_for_esc(self, widget, key_event):
        if key_event.keyval != Gdk.KEY_Escape:
            return

        if self.__settings.prod_mode:
            self.set_keep_above(False)
            self.set_visible(False)


    # Enables window out-of-focus autohiding. You need to call this
    # after a popup menu has been closed.
    def enable_out_of_focus_hide(self, *unused):
        if not self.__settings.autohide:
            return

        if not self.__focus_signal:
            self.__focus_signal = \
                self.connect('focus-out-event', self.__main_lost_focus)


    # Removes the out-of-focus autohiding. You need to call this before
    # displaying popup menus, because they trigger out-of-focus signals!
    # This method can be called as-is, but it is also used as a GTK signal
    # handler callback; the signal handler likes to give all sorts of
    # useless (to us) arguments to the function, so they're collected
    # and ignored.
    def disable_out_of_focus_hide(self, *unused):
        if not self.__settings.autohide:
            return

        if self.__focus_signal:
            self.disconnect(self.__focus_signal)
            self.__focus_signal = None


    # Handler for GTK focus-out-event
    def __main_lost_focus(self, *unused):
        self.autohide()


    # If autohiding is enabled, hides the window when it loses focus.
    # Public method, called from other files.
    def autohide(self, *unused):
        if self.__settings.autohide:
            self.set_keep_above(False)
            self.set_visible(False)


    # Quits the program, if permitted. The signal handlers always call
    # this with "force=True" because they HAVE to kill the program.
    def go_away(self, force=False):
        if force or self.__exit_permitted:
            logging.info('Shutdown initiated')
            self.set_keep_above(False)
            self.set_visible(False)
            Gtk.main_quit()
            return True

        logging.info('Exit not permitted')
        return True


    # TODO: put this in a lambda
    def __try_exit(self, menu, event):
        return self.go_away()


    # --------------------------------------------------------------------------
    # IPC socket command handling


    # Extracts X/Y coordinates from a list
    def __parse_position(self, args):
        if not args:
            return None

        try:
            if args[0] == 'center':
                # Center the menu at the mouse cursor
                from Xlib import display

                # Get mouse position
                data = display.Display().screen().root.query_pointer()._data

                return (
                    int(data['root_x']) - int(WINDOW_WIDTH / 2),
                    int(data['root_y']) - int(WINDOW_HEIGHT / 2)
                )
            elif args[0] == 'corner':
                # Position the lower left corner at the specified
                # coordinates
                return (int(args[1]), int(args[2]))
        except Exception as exception:
            logging.error(exception, exc_info=True)

        return None


    # Socket handler: explicitly hide the window
    def __socket_hide_window(self, data):
        if self.__settings.reset_view_after_start:
            # Go back to the default view
            self.reset_view()

        if self.is_visible():
            logging.debug('Hiding the window')
            self.__search.grab_focus()
            self.set_keep_above(False)
            self.set_visible(False)
        else:
            logging.debug('Already hidden')


    # Socket handler: explicitly show the window
    def __socket_show_window(self, data):
        if self.is_visible():
            logging.debug('Already visible')
        else:
            if self.__settings.reset_view_after_start:
                # Go back to the default view
                self.reset_view()

            coords = self.__parse_position(data)

            if coords:
                logging.debug(coords)
                self.move(coords[0], coords[1])

            if self.__settings.prod_mode:
                self.set_type_hint(Gdk.WindowTypeHint.MENU)

            self.set_keep_above(True)
            self.set_visible(True)
            self.present()

            self.__search.grab_focus()
            self.activate_focus()


    # Socket handler: toggle window visibility
    def __socket_toggle_window(self, data):
        if self.__settings.reset_view_after_start:
            # Go back to the default view
            self.reset_view()

        if self.is_visible():
            logging.debug('Toggling window visibility (hide)')
            self.__search.grab_focus()
            self.set_keep_above(False)
            self.set_visible(False)
        else:
            logging.debug('Toggling window visibility (show)')
            coords = self.__parse_position(data)

            if coords:
                logging.debug(coords)
                self.move(coords[0], coords[1])

            if self.__settings.prod_mode:
                self.set_type_hint(Gdk.WindowTypeHint.MENU)

            self.set_keep_above(True)
            self.set_visible(True)
            self.present()

            self.__search.grab_focus()
            self.activate_focus()


    # Socket handler: update puavo-pkg program state
    def __socket_update_puavopkg(self, data):
        if len(data) != 1:
            logging.warning(
                '__socket_update_puavopkg(): malformed arguments ("%s")', data)
            return

        pkg_id = data[0]

        # Find the target program
        target_id = None
        target_program = None

        for menudata_id, program in self.menudata.programs.items():
            if isinstance(program, menudata.PuavoPkgProgram):
                if program.package_id == pkg_id:
                    target_id = menudata_id
                    target_program = program
                    break

        if not target_program:
            logging.error(
                '__socket_update_puavopkg(): no valid puavo-pkg program with the ID "%s" found',
                pkg_id)
            return

        try:
            # Redetect all puavo-pkg program states
            dynamic_puavopkg_ids = utils.puavo_conf('puavo.pkgs.ui.pkglist', '')
            puavopkg_states = puavopkg.detect_package_states(dynamic_puavopkg_ids)

            # Reload a *single* program
            logging.info('__socket_update_puavopkg(): reloading program "%s"', pkg_id)

            if puavopkg.reload_program(target_program,
                                       puavopkg_states,
                                       self.__settings.language,
                                       self.__dirs_config.desktop_dirs,
                                       self.__icon_locator,
                                       self.__icons):
                logging.info('__socket_update_puavopkg(): program updated, updating the UI')
                self.__create_current_menu()
                self.__update_frequent_programs_list(True)
        except Exception as exception:
            logging.error(exception, exc_info=True)


    # Socket handler: reload menudata
    def __socket_reload_menudata(self, data):
        logging.info('__socket_reload_menudata(): reloading all menudata')
        self.unload_menu_data()
        self.load_menu_data()
        self.current_category = 0
        self.current_menu = None
        self.__create_current_menu()


    def __socket_reload_user_programs(self, data):
        if not self.__settings.show_user_programs:
            logging.warning('__socket_reload_user_programs(): user programs are disabled')
            return

        # Called too early?
        if not self.menudata or not self.__user_programs_loaded:
            logging.warning(
                '__socket_reload_user_programs(): initial loading not done, ' \
                'doing nothing')
            return

        # TODO: The category creation/removal is a somewhat jarring experience,
        # UI-wise. You'll always get thrown back to the default view, even if
        # you were searching for something. This does not happen if the
        # category already exists and its contents merely change.

        # If the program was launched without any user programs, then the
        # special category does not exist yet. It must be created dynamically.
        create_new = False

        if 'category-user-programs' in self.menudata.categories:
            temp_category = self.menudata.categories['category-user-programs']
        else:
            temp_category = menudata.Category()
            create_new = True

        if user_programs.update(self.__settings.user_progs,
                                self.menudata.programs,
                                temp_category,
                                self.__icon_locator,
                                self.__icons,
                                self.__settings.language):
            if create_new:
                # The user programs category does not exist yet, create it
                self.__create_user_category(temp_category)
                self.__rebuild_category_list()
            else:
                # The category already exists, its contents must be
                # live-updated, because it could be currently opened
                self.__update_user_category_view()

                # Do we actually have any user programs?
                have_up = False

                for pid, program in self.menudata.programs.items():
                    if isinstance(program, menudata.UserProgram):
                        have_up = True
                        break

                if (not have_up) and ('category-user-programs' in self.menudata.categories):
                    # We had user programs, but they're gone now.
                    # Remove the empty category.
                    new_index = []

                    for cid in self.menudata.category_index:
                        if cid != 'category-user-programs':
                            new_index.append(cid)

                    self.menudata.category_index = new_index

                    del self.menudata.categories['category-user-programs']
                    self.__rebuild_category_list()

            # Forcibly update the frequent programs list. We don't
            # know if anything actually changed, but it's not easy
            # to detect what actually does change, so just force it.
            self.__update_frequent_programs_list(force=True)


    # Responds to commands sent through the control socket
    def __socket_watcher(self, conn, *args):
        try:
            data = conn.recv(1024)
            data = (data or b'').decode('utf-8').strip().split(' ')

            if not data:
                logging.debug('Received an empty command through the socket?')
                return False

            cmd = data[0]
            data = data[1:]

            logging.debug('Socket command: "%s", arguments: "%s"', cmd, data)

            socket_handlers = {
                'hide': self.__socket_hide_window,
                'show': self.__socket_show_window,
                'toggle': self.__socket_toggle_window,
                'update-puavopkg': self.__socket_update_puavopkg,
                'reload-menudata': self.__socket_reload_menudata,
                'reload-userprogs': self.__socket_reload_user_programs,
            }

            if cmd in socket_handlers:
                socket_handlers[cmd](data)
            else:
                logging.error('Unknown socket command "%s"', cmd)
        except Exception as exception:
            logging.error('Socket command processing failed!')
            logging.error(exception, exc_info=True)

        # MUST RETURN FALSE HERE, otherwise we get stuck in an infinite loop
        return False


    # Accepts incoming IPC socket connections
    def __socket_accept(self, sock, *args):
        # http://rox.sourceforge.net/desktop/node/413.html
        conn, addr = sock.accept()
        GLib.io_add_watch(conn, GLib.IO_IN, self.__socket_watcher)
        return True


    # --------------------------------------------------------------------------
    # Development helpers


    # The devtools menu and its commands
    def __devtools_menu(self, widget, event):
        if self.__settings.prod_mode:
            return

        if event.button != 3:
            return

        def purge(menuitem):
            if self.menudata:
                logging.debug('=' * 20)
                logging.debug('Purging all loaded menu data!')
                logging.debug('=' * 20)
                self.unload_menu_data()

        def reload(menuitem):
            # Remember where we are (a little nice-to-have for development time)
            prev_menu = None
            prev_cat = None

            if self.menudata:
                if self.current_menu:
                    prev_menu = self.current_menu.menudata_id

                if self.menudata.category_index and self.current_category != -1:
                    prev_cat = self.menudata.category_index[self.current_category]

            logging.debug('=' * 20)
            logging.debug('Reloading all menu data!')
            logging.debug('=' * 20)

            # TODO: get rid of this call, so we can retain the old data if
            # we can't load the new data (the loader already supports that)
            self.unload_menu_data()

            if not self.load_menu_data():
                self.error_message('Failed to load menu data',
                                   'See the console for more details')
            else:
                # Try to restore the previous menu and category
                #print('Previous category: "{0}"'.format(prev_cat))
                #print('Previous menu: "{0}"'.format(prev_menu))

                if prev_cat:
                    for index, cat in enumerate(self.menudata.category_index):
                        if cat == prev_cat:
                            logging.debug('Restoring category "%s" after reload',
                                          prev_cat)
                            self.current_category = index
                            self.__category_buttons.set_current_page(index)
                            break

                if prev_menu and (prev_menu in self.menudata.menus):
                    logging.debug('Restoring menu "%s" after reload',
                                  prev_menu)
                    self.current_menu = self.menudata.menus[prev_menu]
                    self.__create_current_menu()
                    self.__back_button.show()

            logging.debug('Menu data reload complete')

        def toggle_autohide(menuitem):
            self.__settings.autohide = not self.__settings.autohide

        def permit_exit(menuitem):
            self.__exit_permitted = not self.__exit_permitted

            if self.__exit_permitted:
                logging.debug('Normal exiting ENABLED')
            else:
                logging.debug('Normal exiting DISABLED')

        def force_exit(menuitem):
            logging.debug('Devmenu force exit initiated!')
            self.go_away(True)

        def dump_program_uses(menuitem):
            by_launches = self.__program_launch_counts.get_frequent_programs()

            for i in by_launches:
                print('%d %s' % (i[0], i[1]))

        dev_menu = Gtk.Menu()

        reload_item = Gtk.MenuItem('(Re)load menu data')
        reload_item.connect('activate', reload)
        reload_item.show()
        dev_menu.append(reload_item)

        if self.menudata:
            remove_item = Gtk.MenuItem('Unload all menu data')
            remove_item.connect('activate', purge)
            remove_item.show()
            dev_menu.append(remove_item)

            dump_item = Gtk.MenuItem('Dump program usage counters')
            dump_item.connect('activate', dump_program_uses)
            dump_item.show()
            dev_menu.append(dump_item)

        sep = Gtk.SeparatorMenuItem()
        sep.show()
        dev_menu.append(sep)

        autohide_item = Gtk.CheckMenuItem('Autohide window')
        autohide_item.set_active(self.__settings.autohide)
        autohide_item.connect('activate', toggle_autohide)
        autohide_item.show()
        dev_menu.append(autohide_item)

        sep = Gtk.SeparatorMenuItem()
        sep.show()
        dev_menu.append(sep)

        permit_exit_item = Gtk.CheckMenuItem('Permit normal program exit')
        permit_exit_item.set_active(self.__exit_permitted)
        permit_exit_item.connect('activate', permit_exit)
        permit_exit_item.show()
        dev_menu.append(permit_exit_item)

        force_exit_item = Gtk.MenuItem('Force program exit')
        force_exit_item.connect('activate', force_exit)
        force_exit_item.show()
        dev_menu.append(force_exit_item)

        # Prevent autohide when the menu is open
        self.disable_out_of_focus_hide()
        dev_menu.connect('deactivate', self.enable_out_of_focus_hide)

        dev_menu.popup(
            parent_menu_shell=None,
            parent_menu_item=None,
            func=None,
            data=None,
            button=1,
            activate_time=0)


# ==============================================================================
# ==============================================================================


# Call this. The system has been split this way so that puavomenu only has to
# parse command line arguments and once it is done, import this file and run
# the menu. If you just run puavomenu from the command line, it tries to import
# all sorts of X libraries and stuff and sometimes that fails and you can't
# even see the help text!
def run_puavomenu(settings, socket, program_start_time):
    logging.info('Entering run_puavomenu()')

    try:
        PuavoMenu(settings, socket, program_start_time)
        Gtk.main()

        # Normal exit, try to remove the socket file but don't explode
        # if it fails
        try:
            os.unlink(settings.socket)
        except OSError:
            pass

    except Exception as exception:
        logging.error(exception, exc_info=True)

    # We get here only in development mode
    logging.info('Exiting run_puavomenu()')
