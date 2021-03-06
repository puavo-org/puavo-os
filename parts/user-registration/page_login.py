# The "Login" page

import gettext

from page_definition import PageDefinition

gettext.bindtextdomain('puavo-user-registration', '/usr/share/locale')
gettext.textdomain('puavo-user-registration')
_tr = gettext.gettext


class PageLogin(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir, main_builder):
        super().__init__(application, parent_window, parent_container, data_dir, main_builder)

        self.load_file('login.glade', 'login')

        self.old_label_for_page_login = self.main_builder.get_object(
            'login_with_existing_account').get_label()
        self.we_are_active = False

        # Setup event handling
        handlers = {
          'on_login_clicked':      self.on_login_clicked,
          'on_password_activated': self.on_password_activated,
          'on_password_changed':   self.maybe_enable_login_button,
          'on_username_activated': self.on_username_activated,
          'on_username_changed':   self.maybe_enable_login_button,
        }
        self.builder.connect_signals(handlers)


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
       have_username = (self.builder.get_object('username').get_text() != '')
       do_login = self.builder.get_object('do_login')
       do_login.set_sensitive(have_password and have_username)


    def swap_with(self, account_page):
        if self.we_are_active:
            self.application.goto_page(account_page)
            self.we_are_active = False
        else:
            self.application.goto_page(self)
            self.we_are_active = True


    def activate(self):
        self.main_builder.get_object('login_with_existing_account').set_label(
          _tr('New User Registration'))
        super().activate()
        self.builder.get_object('username').grab_focus()


    def deactivate(self):
        super().deactivate()
        self.main_builder.get_object('login_with_existing_account').set_label(
            self.old_label_for_page_login)


    def on_login_clicked(self, widget):
        username = self.builder.get_object('username').get_text().strip()
        password = self.builder.get_object('password').get_text()
        self.application.login_locally_from_loginpage(username, password)


    def enable_login_button(self):
        # Return True to show the "Login with existing account" button
        return True
