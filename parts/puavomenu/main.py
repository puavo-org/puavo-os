# PuavoMenu main

import time
import os
import os.path
import socket               # for the IPC socket
import logging
import traceback
import syslog

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import Pango
from gi.repository import GLib
from gi.repository import Gio

from constants import *
import menudata
import iconcache
import buttons
import utils
import utils_gui
import faves
import sidebar
from strings import STRINGS


class PuavoMenu(Gtk.Window):
    def error_message(self, message, secondary_message=None):
        """Show a modal error message box."""

        dialog = Gtk.MessageDialog(parent=self,
                                   flags=Gtk.DialogFlags.MODAL,
                                   type=Gtk.MessageType.ERROR,
                                   buttons=Gtk.ButtonsType.OK,
                                   message_format=message)

        if secondary_message:
            dialog.format_secondary_markup(secondary_message)

        self.disable_out_of_focus_hide()
        dialog.run()
        dialog.hide()
        self.enable_out_of_focus_hide()

    def __init__(self, settings):

        """This is where the magic happens."""

        start_time = time.clock()

        super().__init__()

        self.__settings = settings

        # Ensure the window is not visible until it's ready
        self.set_visible(False)

        self.set_type_hint(Gtk.WindowType.TOPLEVEL)

        # ----------------------------------------------------------------------
        # Set up a domain socket for show/hide messages from the panel
        # button shell extension. This is done early, because if it
        # fails, we simply exit. We can't do *anything* without it.
        # (The only other choice would be to always display the menu,
        # never allowing the user to hide it because without the socket
        # it cannot be reopened.)

        try:
            # Clean leftovers
            os.unlink(self.__settings.socket)
        except OSError:
            pass

        try:
            self.__socket = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
            self.__socket.bind(self.__settings.socket)
        except Exception as exception:
            # Oh dear...
            logging.error('Unable to create a domain socket for IPC!')
            logging.error('Reason: %s', str(exception))
            logging.error('Socket name: "%s"', self.__settings.socket)
            logging.error('This is a fatal error, stopping here.')

            syslog.syslog(syslog.LOG_CRIT,
                          'PuavoMenu IPC socket "%s" creation failed: %s',
                          self.__settings.socket, str(exception))

            syslog.syslog(syslog.LOG_CRIT,
                          'PuavoMenu stops here. Contact Opinsys support.')

            exit(1)

        # Start listening the socket. Use glib's watch functions, then
        # we don't need to use threads (which work too, but are harder
        # to clean up and we'll run into problems with multihtreaded
        # xlib programs).

        # https://developer.gnome.org/pygobject/stable/glib-functions.html#
        #   function-glib--io-add-watch
        GLib.io_add_watch(self.__socket,
                          GLib.IO_IN,
                          self.__socket_watcher)

        # ----------------------------------------------------------------------

        # Exit stuff. By default the program cannot be exited normally.
        self.__exit_permitted = False
        self.connect('delete-event', self.__try_exit)

        # Program, menu and category data
        self.menudata = None

        # Current category (index to menudata.category_index)
        self.current_category = -1

        # The current menu, if any (None if on category top-level)
        self.current_menu = None

        # The current menu/program buttons in the current
        # category and menu, if any
        self.__buttons = []

        # Storage for 48x48 -pixel program and menu icons. Maintained
        # separately from the menu data.
        self.__icons = iconcache.IconCache(48, 48 * 15)

        # Background image for top-level menus
        try:
            if self.__settings.dark_theme:
                image_name = 'folder_dark.png'
            else:
                image_name = 'folder.png'

            # WARNING: Hardcoded image size!
            self.__menu_background = \
                utils_gui.load_image_at_size(self.__settings.res_dir + image_name, 150, 110)
        except Exception as exception:
            logging.error("Can't load the menu background image: %s",
                          str(exception))
            self.__menu_background = None

        # ----------------------------------------------------------------------
        # Create the window elements

        # Set window style
        if self.__settings.prod_mode:
            self.set_skip_taskbar_hint(True)
            self.set_skip_pager_hint(True)
            self.set_deletable(False)       # no close button
            self.set_decorated(False)
        else:
            # makes developing slightly easier
            self.set_skip_taskbar_hint(False)
            self.set_skip_pager_hint(False)
            self.set_deletable(True)
            self.set_decorated(True)
            self.__exit_permitted = True

        # Don't mess with the real menu when running in development mode
        if self.__settings.prod_mode:
            self.set_title('PuavoMenuUniqueName')
        else:
            self.set_title('DevModePuavoMenu')

        self.set_resizable(False)
        self.set_size_request(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Top-level container for all widgets. This is needed, because
        # a window can contain only one child widget and we can have
        # dozens of them. Every widget has a fixed position and size,
        # because the menu isn't user-resizable.
        self.__main_container = Gtk.Fixed()
        self.__main_container.set_size_request(WINDOW_WIDTH,
                                               WINDOW_HEIGHT)

        if not self.__settings.prod_mode:
            # Create the devtools popup menu
            self.menu_signal = \
                self.connect('button-press-event', self.__devtools_menu)

        # ----------------------------------------------------------------------
        # Menus/programs list

        # TODO: Gtk.Notebook isn't the best choice for this

        # Category tabs
        self.__category_buttons = Gtk.Notebook()
        self.__category_buttons.set_size_request(CATEGORIES_WIDTH, -1)
        self.__category_buttons.connect('switch-page',
                                        self.__clicked_category)
        self.__main_container.put(self.__category_buttons,
                                  PROGRAMS_LEFT, MAIN_PADDING)

        # The back button
        self.__back_button = Gtk.Button()
        self.__back_button.set_label('<<')
        self.__back_button.connect('clicked',
                                   self.__clicked_back_button)
        self.__back_button.set_size_request(BACK_BUTTON_WIDTH, -1)
        self.__main_container.put(self.__back_button,
                                  BACK_BUTTON_X,
                                  BACK_BUTTON_Y)

        # The search box

        # filter unwanted characters from queries
        self.__translation_table = \
            dict.fromkeys(map(ord, "*^?{[]}/\\_+=\"\'#%&()'`@$<>|~"),
                          None)

        self.__search = Gtk.SearchEntry()
        self.__search.set_size_request(SEARCH_WIDTH, SEARCH_HEIGHT)
        self.__search.set_max_length(10)     # you won't need more than this
        self.__search_changed_signal = \
            self.__search.connect('changed', self.__do_search)
        self.__search_keypress_signal = \
            self.__search.connect('key-press-event', self.__search_keypress)
        self.__search.set_placeholder_text(
            utils.localize(STRINGS['search_placeholder']))
        self.__main_container.put(
            self.__search,
            PROGRAMS_LEFT + PROGRAMS_WIDTH - SEARCH_WIDTH - MAIN_PADDING,
            MAIN_PADDING)

        # Menu label and description
        self.__menu_title = Gtk.Label()
        self.__menu_title.set_size_request(PROGRAMS_WIDTH, -1)
        self.__menu_title.set_ellipsize(Pango.EllipsizeMode.END)
        self.__menu_title.set_justify(Gtk.Justification.CENTER)
        self.__menu_title.set_alignment(0.0, 0.0)
        self.__menu_title.set_use_markup(True)
        self.__main_container.put(
            self.__menu_title,
            BACK_BUTTON_X + BACK_BUTTON_WIDTH + MAIN_PADDING,
            BACK_BUTTON_Y + 3)

        # The main programs list
        self.__programs_container = Gtk.ScrolledWindow()
        self.__programs_container.set_size_request(PROGRAMS_WIDTH,
                                                   PROGRAMS_HEIGHT)
        self.__programs_container.set_policy(Gtk.PolicyType.NEVER,
                                             Gtk.PolicyType.AUTOMATIC)
        self.__programs_container.set_shadow_type(Gtk.ShadowType.NONE)
        self.__programs_icons = Gtk.Fixed()
        self.__programs_container.add_with_viewport(self.__programs_icons)
        self.__main_container.put(self.__programs_container,
                                  PROGRAMS_LEFT, PROGRAMS_TOP)

        # Placeholder for empty categories, menus and search results
        self.__empty = Gtk.Label()
        self.__empty.set_size_request(PROGRAMS_WIDTH, PROGRAMS_HEIGHT)
        self.__empty.set_use_markup(True)
        self.__empty.set_justify(Gtk.Justification.CENTER)
        self.__empty.set_alignment(0.5, 0.5)
        self.__main_container.put(self.__empty,
                                  PROGRAMS_LEFT, PROGRAMS_TOP)

        # Faves list
        self.__faves_sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        self.__faves_sep.set_size_request(PROGRAMS_WIDTH, 1)
        self.__main_container.put(self.__faves_sep,
                                  PROGRAMS_LEFT,
                                  PROGRAMS_TOP + PROGRAMS_HEIGHT + MAIN_PADDING)

        self.__faves = faves.FavesList(self, self.__settings)
        self.__faves.set_size_request(PROGRAMS_WIDTH,
                                      PROGRAM_BUTTON_HEIGHT + 2)
        self.__main_container.put(self.__faves,
                                  PROGRAMS_LEFT, FAVES_TOP)

        # ----------------------------------------------------------------------
        # The sidebar: the user avatar, buttons, host infos

        utils_gui.create_separator(container=self.__main_container,
                                   x=SIDEBAR_LEFT - MAIN_PADDING,
                                   y=MAIN_PADDING,
                                   w=1,
                                   h=WINDOW_HEIGHT - (MAIN_PADDING * 2),
                                   orientation=Gtk.Orientation.VERTICAL)

        self.__sidebar = sidebar.Sidebar(self, self.__settings)

        self.__main_container.put(self.__sidebar.container,
                                  SIDEBAR_LEFT,
                                  SIDEBAR_TOP)

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
        # UI done

        self.add(self.__main_container)
        self.__main_container.show()

        # DO NOT CALL self.show_all() HERE, the window has hidden elements
        # that are shown/hidden on demand. And we don't even have any
        # menu data yet to show.

        end_time = time.clock()
        utils.log_elapsed_time('Window init time', start_time, end_time)

        # ----------------------------------------------------------------------
        # Load menu data

        # Finally, load the menu data and show the UI
        self.load_menu_data()

        # This is a bad, bad situation that should never happen in production.
        # It will happen one day.
        if self.menudata is None or len(self.menudata.programs) == 0:
            if self.__settings.prod_mode:
                self.__show_empty_message(STRINGS['menu_no_data_at_all_prod'])
            else:
                self.__show_empty_message(STRINGS['menu_no_data_at_all_dev'])

    # --------------------------------------------------------------------------
    # Menus and programs list handling

    # Replaces the existing menu and program buttons (if any) with new
    # buttons. The new button list can be empty.
    def __fill_programs_list(self, new_buttons, show=False):
        if show:
            self.__programs_icons.hide()

        # Clear the old buttons first
        for button in self.__buttons:
            button.destroy()

        self.__buttons = []

        xpos = 0
        ypos = 0

        # Insert the new icons and arrange them into rows
        for index, button in enumerate(new_buttons):
            self.__programs_icons.put(button, xpos, ypos)
            self.__buttons.append(button)

            xpos += PROGRAM_BUTTON_WIDTH

            if (index + 1) % PROGRAMS_PER_ROW == 0:
                xpos = 0
                ypos += PROGRAM_BUTTON_HEIGHT

        self.__programs_icons.show_all()

        if show:
            self.__programs_icons.show()

    # (Re-)Creates the current category or menu view
    def __create_current_menu(self):
        if self.menudata is None:
            return

        new_buttons = []

        self.__empty.hide()

        if self.current_menu is None:
            # Top-level category view
            if len(self.menudata.category_index) > 0 and \
               self.current_category < len(self.menudata.category_index):

                # We have a valid category
                cat = self.menudata.categories[
                    self.menudata.category_index[self.current_category]]

                # Menus first...
                for menu in cat.menus:
                    if menu.hidden:
                        continue

                    button = buttons.MenuButton(
                        self, menu.name, menu.icon, menu.description, menu,
                        self.__menu_background)

                    button.connect('clicked', self.__clicked_menu_button)
                    new_buttons.append(button)

                # ...then programs
                for program in cat.programs:
                    if program.hidden:
                        continue

                    button = buttons.ProgramButton(
                        self, program.name, program.icon,
                        program.description, program)

                    button.connect('clicked', self.clicked_program_button)
                    new_buttons.append(button)

            # Handle special situations
            if len(new_buttons) == 0:
                self.__show_empty_message(STRINGS['menu_empty_category'])

        else:
            # Submenu view, have only programs (no submenu support yet)
            for program in self.current_menu.programs:
                if program.hidden:
                    continue

                button = buttons.ProgramButton(
                    self, program.name, program.icon,
                    program.description, program)

                button.connect('clicked', self.clicked_program_button)
                new_buttons.append(button)

            # Handle special situations
            if len(self.current_menu.programs) == 0:
                self.__show_empty_message(STRINGS['menu_empty_menu'])

        self.__fill_programs_list(new_buttons, True)

        # Update the menu title
        if self.current_menu is None:
            self.__menu_title.hide()
            self.__back_button.hide()
        else:
            # TODO: "big" and "small" are not good sizes, we need to be explicit
            if self.current_menu.description:
                self.__menu_title.set_markup(
                    '<big>{0}</big>  <small>{1}</small>'.
                    format(self.current_menu.name, self.current_menu.description))
            else:
                self.__menu_title.set_markup(
                    '<big>{0}</big>'.format(self.current_menu.name))

            self.__menu_title.show()
            self.__back_button.show()

    # --------------------------------------------------------------------------
    # Menu/category navigation

    # Shows an "empty" message in the main programs list. Used when a
    # menu/category is empty, or there are no search results.
    def __show_empty_message(self, msg):
        if isinstance(msg, dict):
            msg = utils.localize(msg)

        self.__empty.set_markup(
            '<span color="#888" size="large"><i>{0}</i></span>'.format(msg))
        self.__empty.show()

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
    # Button click handlers

    # Called directly from ProgramButton
    def add_program_to_desktop(self, program):
        """Creates a desktop shortcut to a program."""

        if not self.__settings.desktop_dir:
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
                utils.localize(STRINGS['desktop_link_failed']),
                str(exception))

    # Called directly from ProgramButton
    def add_program_to_panel(self, program):
        logging.info('Adding program "%s" (id="%s") to the bottom panel',
                     program.name, program.name)

        try:
            utils_gui.create_panel_link(program)
        except Exception as exception:
            logging.error('Panel icon creation failed')
            logging.error(str(exception))

            self.error_message(utils.localize(STRINGS['panel_link_failed']),
                               str(exception))

    # Called directly from ProgramButton
    def remove_program_from_faves(self, p):
        logging.info('Removing program "%s" from the faves', p.name)
        p.uses = 0
        self.__faves.update(self.menudata.programs)

    # Launch a program. This is a public method, it is called from other
    # files (buttons and faves) to launch programs.
    def clicked_program_button(self, button):
        program = button.data
        program.uses += 1

        logging.info('Clicked program button "%s", usage counter is %d',
                     program.menudata_id, program.uses)

        self.__faves.update(self.menudata.programs)

        if program.command is None:
            logging.error('No command defined for program "%s"', program.name)
            return

        # Try to launch the program. Use Gio's services, as Gio understands the
        # "Exec=" keys and we don't have to spawn shells with pipes and "sh".
        try:
            if self.__settings.prod_mode:
                # Spy the user and log what programs they use. This information
                # is then sent to various TLAs around the world and used in all
                # sorts of nefarious classified black operations.
                syslog.syslog(syslog.LOG_INFO, 'Launching program "{0}", command="{1}"'.
                              format(program.menudata_id, program.command))

                # Just kidding. The reason program starts are logged to syslog
                # is actually really simple: you can grep the log and count
                # which programs are actually used and how many times.

                # Of course this only logs programs that are started through
                # Puavomenu, but we decided to ignore this for now.

            logging.info('Executing "%s"', program.command)

            if program.program_type in (PROGRAM_TYPE_DESKTOP, PROGRAM_TYPE_CUSTOM):
                # Set the program name to empty string ('') to force some (KDE)
                # programs to use their default window titles. These programs
                # have command-line parameters like "-qwindowtitle" or "-caption"
                # and Gio, when launching the program, sets the "%c" argument
                # (in the Exec= key) to the program's name it takes from the
                # command (program.command). This is Wrong(TM), but during
                # testing I noticed that if we leave it empty (*NOT* None
                # because that triggers the unwanted behavior!) then these
                # programs will use their own default titles.
                Gio.AppInfo.create_from_commandline(program.command, '', 0).launch()
            elif program.program_type == PROGRAM_TYPE_WEB:
                Gio.AppInfo.launch_default_for_uri(program.command, None)
            else:
                raise RuntimeError('Unknown program type "{0}"'.
                                   format(program.program_type))

            # Of course, we never check the return value here, so we
            # don't know if the command actually worked...

            self.autohide()

            if self.__settings.reset_view_after_start:
                # Go back to the default view
                self.reset_view()

        except Exception as exception:
            logging.error('Could not launch program "%s": %s',
                          program.command, str(exception))
            self.error_message(utils.localize(STRINGS['program_launching_failed']),
                               str(exception))
            return False

    # --------------------------------------------------------------------------
    # Searching

    # Returns the current search term, filtered and cleaned
    def __get_search_text(self):
        return self.__search.get_text().strip().translate(self.__translation_table)

    # Searches the programs list using a string, then replaces the menu list
    # with results
    def __do_search(self, edit):
        if self.menudata is None:
            return

        key = self.__get_search_text()

        if len(key) == 0:
            self.__create_current_menu()
            return

        matches = self.menudata.search(key)

        if len(matches) > 0:
            self.__empty.hide()
        else:
            self.__show_empty_message(STRINGS['search_no_results'])

        # create new buttons for results
        new_buttons = []

        for m in matches:
            b = buttons.ProgramButton(self, m.name, m.icon, m.description, m)
            b.connect('clicked', self.clicked_program_button)
            new_buttons.append(b)

        self.__fill_programs_list(new_buttons, True)

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
            if len(self.__get_search_text()):
                # Cancel an ongoing search
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
            if len(self.__get_search_text()) and (len(self.__buttons) == 1):
                # There's only one search match and the user pressed
                # Enter, so launch it!
                self.clicked_program_button(self.__buttons[0])
                self.__clear_search_field()
                self.__create_current_menu()

        return False

    # --------------------------------------------------------------------------
    # Menu data loading and handling

    def load_menu_data(self):
        """Loads menu data and sets up the UI. Returns false if
        something fails."""

        try:
            self.menudata = menudata.Menudata()

            self.menudata.load(self.__settings.language,
                               self.__settings.menu_dir,
                               utils.puavo_conf('puavo.puavomenu.tags', 'default'),
                               self.__icons)

        except Exception as exception:
            logging.fatal('Could not load menu data!')
            logging.error(exception, exc_info=True)

            if self.__settings.prod_mode:
                # Log for later examination
                syslog.syslog(syslog.LOG_CRIT, 'Could not load menu data!')
                syslog.syslog(syslog.LOG_CRIT, traceback.format_exc())

            self.menudata = None
            return False

        # Prepare the user interface
        for index in self.menudata.category_index:
            cat = self.menudata.categories[index]

            if cat.hidden:
                continue

            frame = Gtk.Frame()
            label = Gtk.Label(cat.name)
            frame.show()
            label.show()
            self.__category_buttons.append_page(frame, label)

        if len(self.menudata.category_index) > 0:
            self.__category_buttons.show()

        self.__create_current_menu()
        self.__programs_container.show()

        if self.__settings.enable_faves_saving:
            faves.load_use_counts(self.menudata.programs, self.__settings.user_dir)

        self.__faves.update(self.menudata.programs)
        self.__faves_sep.show()
        self.__faves.show()

        self.__search.show()
        self.__search.grab_focus()

        return True

    def unload_menu_data(self):
        """Completely removes all menu data. Hides everything programs-
        related from the UI."""

        if self.__settings.prod_mode:
            return

        self.__category_buttons.hide()

        num_pages = self.__category_buttons.get_n_pages()

        for index in range(0, num_pages):
            self.__category_buttons.remove_page(-1)

        for button in self.__buttons:
            button.destroy()

        self.__buttons = []

        self.__clear_search_field()
        self.__back_button.hide()
        self.__search.hide()
        self.__empty.hide()

        self.__programs_icons.hide()
        self.__programs_container.hide()

        self.__faves_sep.hide()
        self.__faves.clear()
        self.__faves.hide()

        self.__menu_title.hide()
        self.__programs_container.hide()

        self.menudata = None
        self.current_category = -1
        self.current_menu = None

        self.__icons.clear()

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
        else:
            logging.debug('Ignoring Esc in development mode')

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

    # (Re)enables window out-of-focus autohiding. You need to call this
    # after a popup menu has been closed.
    def enable_out_of_focus_hide(self, *unused):
        if not self.__settings.autohide:
            return

        if not self.__focus_signal:
            self.__focus_signal = \
                self.connect('focus-out-event', self.__main_lost_focus)

    def __main_lost_focus(self, *unused):
        self.autohide()

    def __search_out(self, *unused):
        self.__search.grab_focus()

    # If autohiding is enabled, hides the window when it loses focus. Public method, called
    # from other files.
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
        else:
            logging.info('Exit not permitted')
            return True

    # TODO: put this in a lambda
    def __try_exit(self, menu, event):
        return self.go_away()

    # Extracts X/Y coordinates from a list
    def __parse_position(self, args):
        if len(args) == 0:
            return None

        try:
            if args[0] == 'center':
                # Center the menu at the mouse cursor
                from Xlib import display

                data = display.Display().screen().root.query_pointer()._data

                return (
                    int(data['root_x']) - int(WINDOW_WIDTH / 2),
                    int(data['root_y']) - int(WINDOW_HEIGHT / 2)
                )
            elif args[0] == 'corner':
                # Position the lower left corner at the specified
                # coordinates
                # TODO: use window gravity for this?
                return (int(args[1]), int(args[2]) - WINDOW_HEIGHT)
        except Exception:
            pass

        return None

    # Responds to commands sent through the control socket
    def __socket_watcher(self, source, condition, *args):
        try:
            data, _ = self.__socket.recvfrom(1024)
            data = (data or b'').decode('utf-8').strip().split(' ')

            if len(data) == 0:
                logging.debug('Received an empty command through the socket?')
                return True

            cmd = data[0]
            data = data[1:]

            logging.debug('Socket command: "%s"', cmd)
            logging.debug('Socket arguments: "%s"', data)

            if cmd == 'hide':
                # Hide the window

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
            elif cmd == 'show':
                # Show the window

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

                    self.set_keep_above(True)
                    self.set_visible(True)
                    self.present()

                    self.__search.grab_focus()
                    self.activate_focus()
            elif cmd == 'toggle':
                # Toggle the window visibility

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

                    self.set_keep_above(True)
                    self.set_visible(True)
                    self.present()

                    self.__search.grab_focus()
                    self.activate_focus()
            else:
                logging.warning('Unknown command "%s" received, args="%s"',
                                cmd, data)
        except Exception as exception:
            logging.error('Socket command processing failed!')
            logging.error(str(exception))

        # False will remove the handler, that's not what we want
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

                if len(self.menudata.category_index) > 0 and \
                   self.current_category != -1:
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
                print('Previous category: "{0}"'.format(prev_cat))
                print('Previous menu: "{0}"'.format(prev_menu))

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
            logging.debug('Normal exiting ' +
                          ('ENABLED' if self.__exit_permitted else 'DISABLED'))

        def force_exit(menuitem):
            logging.debug('Devmenu force exit initiated!')
            self.go_away(True)

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


# Call this. The system has been split this way so that puavomenu only
# has to parse arguments and once it is one, import this file and run
# the menu. If you just run puavomenu from the command line, it tries
# to import all sorts of X libraries and stuff and sometimes that fails
# and you can't even see the help text!
def run_puavomenu(settings):
    logging.info('Entering run_puavomenu()')

    try:
        menu = PuavoMenu(settings)
        Gtk.main()

        # Normal exit, try to remove the socket file but don't explode
        # if it fails
        try:
            os.unlink(settings.socket)
        except OSError:
            pass

    except Exception as exception:
        logging.error(exception, exc_info=True)

    logging.info('Exiting run_puavomenu()')
