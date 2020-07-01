# Base page class for all child dialogs

import os

import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk


class PageDefinition:
    def __init__(self, application, parent_window, parent_container, data_dir, main_builder):
        self.application = application
        self.parent_window = parent_window
        self.parent_container = parent_container
        self.data_dir = data_dir
        self.main_builder = main_builder

        # The Gtk.Builder object for this child
        self.builder = None

        # This is the actual child dialog, shown and hidden on demand
        self.child = None


    def activate(self):
        if self.child:
            self.parent_container.add(self.child)
            self.parent_container.show_all()


    def deactivate(self):
        if self.child:
            self.parent_container.remove(self.child)


    # Loads a Glade UI file and locates the child container in it
    def load_file(self, file_name, container_name):
        self.builder = Gtk.Builder()
        self.builder.set_translation_domain('puavo-user-registration')
        self.builder.add_from_file(os.path.join(self.data_dir, file_name))
        self.child = self.builder.get_object(container_name)


    def get_main_title(self):
        # Return None here to completely hide the title
        return None


    def enable_desktop_button(self):
        # Return False to hide the "Go to desktop" button
        return True


    def enable_login_button(self):
        # Return True to show the "Login with existing account" button
        return False
