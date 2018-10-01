# "Faves", ie. a list of the most often used programs

import gi
gi.require_version('Gtk', '3.0')        # explicitly require Gtk3, not Gtk2
from gi.repository import Gtk

from constants import PROGRAM_BUTTON_WIDTH, NUMBER_OF_FAVES
import logger

from buttons import ProgramButton
from settings import SETTINGS


def _save_use_counts(all_programs):
    """Serialize the IDs and use counts for programs with use counts
    over zero. Called automatically through FavesList.update()."""

    if not SETTINGS.enable_faves_saving:
        return

    out = ''

    # Whitespace is not permitted in program IDs, so this works
    for name, p in all_programs.items():
        if p.uses > 0:
            out += '{0} {1}\n'.format(name, p.uses)

    try:
        from os.path import join as path_join
        open(path_join(SETTINGS.user_dir, 'faves'), 'w').write(out)
    except Exception as e:
        logger.error('Could not save favorites: {0}'.format(e))


def load_use_counts(all_programs):
    """Unserialize fave IDs and their counts."""

    if not SETTINGS.enable_faves_saving:
        return

    from os.path import join as path_join, isfile as is_file

    faves_file = path_join(SETTINGS.user_dir, 'faves')

    if not is_file(faves_file):
        return

    for row in open(faves_file, 'r').readlines():
        parts = row.strip().split()

        if len(parts) != 2:
            continue

        if not parts[0] in all_programs:
            logger.warn('Program "{0}" listed in faves.yaml, but it does '
                        'not exist in the menu data'.format(parts[0]))
            continue

        try:
            all_programs[parts[0]].uses = int(parts[1])
        except:
            # the use count probably wasn't an integer...
            logger.warn('Could not set the use count for program "{0}"'.
                        format(parts[0]))


class FavesList(Gtk.ScrolledWindow):
    """The most often used programs list."""

    def __init__(self, parent):
        super().__init__()

        self.__parent = parent

        self.__fave_buttons = []
        self.__prev_fave_ids = []

        # Container for the icons
        self.__icons = Gtk.Fixed()

        # No scrollbars
        self.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER)

        # No borders
        self.set_shadow_type(Gtk.ShadowType.NONE)

        self.add_with_viewport(self.__icons)


    def clear(self):
        """Removes all buttons from the faves list."""

        for b in self.__fave_buttons:
            b.destroy()

        self.__fave_buttons = []
        self.__prev_fave_ids = []

        logger.info('Faves list cleared')


    def update(self, all_programs):
        """Recreates the fave buttons if program launch counts have
        changed enough since the last update."""

        if len(self.__fave_buttons) == 0:
            self.__prev_fave_ids = []

        # Extract the IDs and counts of the N most used programs. Sort
        # first by use count, then by title. Titles are required to get
        # the order stable (Python dicts are not in any particular order
        # in Python 3.5, so programs that have identical use counts are
        # inserted on the list in random order and they tend to switch
        # positions constantly; we need to break that randomness).
        faves = [(name, p.uses, p.title)
                 for name, p in all_programs.items() if p.uses > 0]
        faves = sorted(faves,
                       key=lambda p: (p[1], p[2]), reverse=True)[0:NUMBER_OF_FAVES]

        # Do nothing if the list order hasn't changed
        new_ids = [f[0] for f in faves]

        if self.__prev_fave_ids == new_ids:
            return

        # Something has changed, recreate the buttons
        logger.info('Faves order has changed ({0} -> {1})'.
                    format(self.__prev_fave_ids, new_ids))

        _save_use_counts(all_programs)

        self.__prev_fave_ids = new_ids

        for b in self.__fave_buttons:
            b.destroy()

        self.__fave_buttons = []

        for i, f in enumerate(faves):
            p = all_programs[f[0]]
            # use self.__parent as the parent, so popup menu handlers
            # will call the correct methods from the main window class
            button = ProgramButton(self.__parent, p.title, p.icon, p.description,
                                   data=p, is_fave=True)
            button.connect('clicked', self.__parent.clicked_program_button)
            self.__fave_buttons.append(button)
            self.__icons.put(button, i * PROGRAM_BUTTON_WIDTH, 0)

        self.__icons.show_all()
