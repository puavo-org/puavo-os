# Loads, updates and maintains user programs

import os
import logging
from pathlib import Path
import time
import threading
import socket

import utils
import menudata
import loaders.menudata_loader as menudata_loader
import loaders.dotdesktop_loader


class UserProgramsManager:
    def __init__(self, base_dir, language):
        self.__base_dir = base_dir
        self.__language = language
        self.__file_cache = {}


    def reset(self):
        self.__file_cache = {}


    # Scans the user programs directory and creates, removes and updates
    # user programs. Returns True if something actually changed.
    def update(self, programs, category, icon_locator, icon_cache):
        if self.__base_dir is None:
            return False

        start_time = time.perf_counter()

        if not os.path.isdir(self.__base_dir) or not os.access(self.__base_dir, os.R_OK):
            logging.warning(
                "UserProgramsManager::update(): can't access directory \"%s\"", self.__base_dir)
            return False

        # Get a list of current .desktop files
        new_files = {}
        seen = set()

        for name in Path(self.__base_dir).rglob('*.desktop'):
            try:
                # Generate a unique ID for this program
                basename = os.path.splitext(name.name)[0]
                program_id = 'user-program-' + basename

                if program_id in seen:
                    # If you really want to duplicate a program, you have to rename
                    # the duplicate .desktop file
                    continue

                seen.add(program_id)

                stat = os.stat(name)

                new_files[name] = {
                    'modified': stat.st_mtime,
                    'size': stat.st_size,
                    'program_id': program_id,
                }
            except Exception as exception:
                logging.fatal('Error occurred when scanning for user programs:')
                logging.error(exception, exc_info=True)

        # Detect added, removed and changed files
        existing_keys = set(self.__file_cache.keys())
        new_keys = set(new_files.keys())

        added = new_keys - existing_keys
        removed = existing_keys - new_keys
        changed = set()

        current = set()

        for pid, program in programs.items():
            if isinstance(program, menudata.UserProgram):
                current.add(pid)

        for name in existing_keys.intersection(new_keys):
            if self.__file_cache[name]['modified'] != new_files[name]['modified'] or \
               self.__file_cache[name]['size'] != new_files[name]['size']:
                changed.add(name)

        something_changed = False

        # Unload removed programs first. This way, if a .desktop file is renamed, the new
        # program ID won't be a duplicate (the renamed program would appear on the next
        # update).
        for name in removed:
            pid = self.__file_cache[name]['program_id']

            if pid in current:
                current.remove(pid)

            if pid not in programs:
                # what is going on?
                continue

            program = programs[pid]

            if program.icon and program.original_icon_name:
                del icon_cache[program.original_icon_name]

            del programs[pid]
            something_changed = True

        # Load new files
        for name in added:
            pid = new_files[name]['program_id']

            program = menudata.UserProgram()
            program.menudata_id = pid
            program.original_desktop_file = os.path.basename(name)
            program.filename = name
            program.modified = new_files[name]['modified']
            program.size = new_files[name]['size']

            if self.__load_user_program(program, name, icon_locator, icon_cache):
                programs[pid] = program
                something_changed = True
                current.add(pid)

        # Reload changed files
        for name in changed:
            pid = new_files[name]['program_id']

            if pid not in programs:
                # what did you do?!
                continue

            program = programs[pid]

            if self.__load_user_program(program, name, icon_locator, icon_cache):
                something_changed = True
            else:
                logging.error('Changed user program "%s" not updated', name)

        # Rebuild the list of programs in the specified user category
        if something_changed:
            prog_list = []

            for pid in current:
                if not programs[pid].name:
                    continue

                prog_list.append((pid, programs[pid].name.lower()))

            # the files can be in arbitrary order, so sort
            # the user programs alphabetically
            prog_list.sort(key=lambda p: p[1])

            category.program_ids = []

            for prog in prog_list:
                category.program_ids.append(prog[0])

        self.__file_cache = new_files

        end_time = time.perf_counter()

        utils.log_elapsed_time('UserProgramsManager::update(): user programs update',
                               start_time, end_time)

        # Trigger a menu buttons rebuild if something actually changed
        return something_changed


    # Loads the .desktop file for a single program and builds
    # a program object out of it
    def __load_user_program(self,
                            program,            # a UserProgram instance
                            filename,           # .desktop file name
                            icon_locator,       # where to find icons
                            icon_cache):        # the icon cache to use

        # Load the .desktop file
        try:
            desktop_data = loaders.dotdesktop_loader.load(filename)

            if 'Desktop Entry' not in desktop_data:
                raise RuntimeError('missing "Desktop Entry" section')
        except Exception as exc:
            logging.error(
                'Could not load the desktop file "%s" for user program:',
                filename)
            logging.error(str(exc))
            return False

        # If the .desktop file was created by us, reject it, because
        # otherwise we'd end up creating loops. If you edit an existing
        # .desktop file and add (or remove) this key, it WILL cause
        # problems, but then it'll be your own problem.
        if 'X-Puavomenu-Created' in desktop_data['Desktop Entry']:
            logging.info(
                '.desktop file "%s" was created by us, not adding it to the user programs list',
                filename
            )
            return False

        # Normally this would contain all the data loaded from menudata JSON
        # file(s), but those don't exist here
        final_data = {}

        menudata_loader.merge_json_and_desktop_data(
            final_data, desktop_data['Desktop Entry'], self.__language)

        if final_data.get('command', None) is None:
            logging.warning('.desktop file "%s" does not specify a command to run',
                            filename)
            return False

        program.name = final_data.get('name', None)
        program.command = final_data.get('command', None)
        program.description = final_data.get('description', None)
        program.keywords = final_data.get('keywords', frozenset())

        # Locate the icon file
        icon_name = final_data.get('icon', None)
        icon_file, _ = icon_locator.locate_icon(icon_name)

        if program.original_icon_name:
            if program.original_icon_name == icon_file:
                # This program was reloaded, but the icon did not change
                return True

            # The icon did change, remove the old icon
            del icon_cache[program.original_icon_name]

        # Set the new icon
        if icon_file:
            try:
                program.icon, usable = icon_cache.load_icon(icon_file)
            except BaseException as exc:
                logging.error(
                    'User program icon not loaded, load_icon() threw an exception: %s',
                    str(exc))
                program.icon = None
                usable = False

            if not usable:
                logging.warning('Found icon "%s" for user program "%s" (file "%s"), ' \
                                'but the icon could not be loaded',
                                icon_name, program.name, filename)
        else:
            if icon_name:
                logging.warning('Unable to locate icon "%s" for user program "%s" (file "%s")',
                                icon_name, program.name, filename)
            else:
                logging.warning('User program "%s" (file "%s") has no icon defined for it',
                                program.name, filename)
            program.icon = None

        program.original_icon_name = icon_name

        return True


class UpdaterThread(threading.Thread):
    # How long to wait between updates, in seconds
    UPDATE_WAIT = 60 * 5

    def __init__(self, socket_file):
        super().__init__()
        self.socket_file = socket_file
        logging.info('User programs update thread started')


    def run(self):
        while True:
            time.sleep(self.UPDATE_WAIT)

            # Send the message through the socket instead of calling the update method
            # directly. Avoids thread concurrency problems. Maybe. I hope.
            try:
                sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                sock.connect(self.socket_file)
                sock.send(b'reload-userprogs')
                sock.close()
            except Exception as exception:
                logging.error('Failed to update user programs: %s', str(exception))
