# The "Login" page

import gettext
import gi

from gi.repository import GLib

from logger import log

from page_definition import PageDefinition

gettext.bindtextdomain('puavo-user-registration', '/usr/share/locale')
gettext.textdomain('puavo-user-registration')
_tr = gettext.gettext


class PageLogin(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir, main_builder):
        super().__init__(application, parent_window, parent_container, data_dir, main_builder)

        self.load_file('login.glade', 'login')

        self.no_account_button = self.builder.get_object('no_account_button')
        self.primary_user_info = self.builder.get_object('primary_user_info')
        self.username_field    = self.builder.get_object('username')

        # Setup event handling
        handlers = {
          'on_login_clicked':      self.on_login_clicked,
          'on_no_account_clicked': self.on_no_account_clicked,
          'on_password_activated': self.on_password_activated,
          'on_password_changed':   self.maybe_enable_login_button,
          'on_previous_clicked':   self.on_previous_clicked,
          'on_username_activated': self.on_username_activated,
          'on_username_changed':   self.maybe_enable_login_button,
        }
        self.builder.connect_signals(handlers)


    def set_primary_user(self, primary_user):
        log.info('this host is previously registered to "%s"', primary_user)

        msg = _tr("This host has already been registered\n" \
                    + "to user \"%s\".  Please provide\n" \
                    + "the password to start using this host.\n") \
                 % primary_user
        self.primary_user_info.set_markup(
          '<span color="%s">%s</span>' % ('#faa', msg))
        self.username_field.set_text(primary_user)
        self.username_field.set_sensitive(False)
        self.no_account_button.set_sensitive(False)


    def get_main_title(self):
       return _tr('Login')


    def on_password_activated(self, widget):
       do_login_button = self.builder.get_object('do_login')
       do_login_button.grab_focus()
       self.on_login_clicked(do_login_button)


    def on_username_activated(self, widget):
       self.builder.get_object('password').grab_focus()


    def maybe_enable_login_button(self, widget):
       have_password = (self.builder.get_object('password').get_text() != '')
       have_username = (self.username_field.get_text() != '')
       do_login = self.builder.get_object('do_login')
       do_login.set_sensitive(have_password and have_username)


    def activate(self):
        super().activate()
        self.builder.get_object('username').grab_focus()


    def on_previous_clicked(self, *args):
        self.application.previous_page()


    def on_no_account_clicked(self, widget):
       self.application.next_page()


    def enable_inputs(self, state):
        object_names = [ 'username', 'password', 'do_login',
                         'login_previous_page', 'no_account_button' ]
        for obj in object_names:
          self.builder.get_object(obj).set_sensitive(state)


    def do_login(self):
        username = self.builder.get_object('username').get_text().strip()
        password = self.builder.get_object('password').get_text()

        log.info('user tries to log in from login form with username="%s"',
                 username)

        self.application.login_locally_from_loginpage(username, password)

        self.enable_inputs(True)

        return False


    def on_login_clicked(self, widget):
        self.enable_inputs(False)
        GLib.timeout_add(50, self.do_login)
