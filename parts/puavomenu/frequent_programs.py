# Frequently-used programs usage tracking

import logging
import os.path

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk

from constants import PROGRAM_BUTTON_WIDTH, PROGRAM_COL_PADDING

import buttons.program


class ProgramLaunchesCounter:
    STATS_FILE = 'program_launches'


    def __init__(self, directory, enabled):
        self.__launches = {}
        self.__directory = directory
        self.__enabled = enabled


    def clear(self):
        self.__launches = {}


    def increment(self, program_id):
        if program_id in self.__launches:
            self.__launches[program_id] += 1
        else:
            self.__launches[program_id] = 1

        self.save()


    def remove(self, program_id):
        if program_id in self.__launches:
            del self.__launches[program_id]
            self.save()


    def get_frequent_programs(self):
        by_launches = [(ctr, pid) for pid, ctr in self.__launches.items()]
        return sorted(by_launches, key=lambda p: (p[0], p[1]), reverse=True)


    def save(self):
        if not self.__enabled:
            return

        out = ''

        # Whitespace is not permitted in program IDs, so this works
        for name, count in self.__launches.items():
            out += '{0} {1}\n'.format(count, name)

        filename = os.path.join(self.__directory, self.STATS_FILE)

        try:
            with open(filename, 'w') as f:
                f.write(out)
        except Exception as exception:
            logging.error(
                'Could not save program usage counts: %s',
                str(exception))


    def load(self):
        if not self.__enabled:
            return

        filename = os.path.join(self.__directory, self.STATS_FILE)

        if not os.path.isfile(filename):
            # no big deal
            return

        for row in open(filename, 'r').readlines():
            parts = row.strip().split(' ')

            if len(parts) != 2:
                continue

            try:
                self.__launches[parts[1]] = int(parts[0])
            except Exception as exception:
                # the use count probably wasn't an integer...
                logging.warning(
                    'Could not set the use count for program "%s": %s',
                    parts[0], str(exception))


# The most frequently used programs list
class FrequentProgramsList(Gtk.ScrolledWindow):
    def __init__(self, parent):
        super().__init__(name='frequent')

        self.__parent = parent

        # Usage count tracking
        self.__prev_items = []

        # No scrollbars or borders
        self.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER)
        self.set_shadow_type(Gtk.ShadowType.NONE)

        # Container for the icons
        self.__container = Gtk.Fixed()
        self.add_with_viewport(self.__container)


    def clear(self):
        self.__prev_items = []


    # Recreates the buttons on the list if its content have changed
    def update(self, current_items, all_programs, settings, icon_cache, force=False):
        # Do nothing if the list hasn't changed (but allow override)
        if self.__prev_items == current_items and not force:
            return

        # Something has changed, recreate the buttons
        logging.info('Frequently-used programs order has changed (%s -> %s)',
                     str(self.__prev_items), str(current_items))

        self.__prev_items = current_items

        for widget in self.__container.get_children():
            widget.destroy()

        x = 0

        for item in current_items:
            try:
                program = all_programs[item]

                # use self.__parent as the parent, so popup menu handlers
                # will call the correct methods from the main window class
                button = buttons.program.ProgramButton(
                    self.__parent,
                    settings,
                    program.name,
                    (icon_cache, program.icon),
                    program.description,
                    data=program,
                    is_fave=True)

                button.connect('clicked', self.__parent.clicked_program_button)
                self.__container.put(button, x, 0)
                x += PROGRAM_BUTTON_WIDTH + PROGRAM_COL_PADDING
            except Exception as ex:
                logging.error("Can't create a frequently-used program button: %s",
                              str(ex))

        self.__container.show_all()
