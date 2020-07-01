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


    def get_main_title(self):
       return _tr('Login')


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


    def deactivate(self):
        super().deactivate()
        self.main_builder.get_object('login_with_existing_account').set_label(
            self.old_label_for_page_login)



    def on_login_clicked(self, *args):
        print("login clicked, yeah")


    def enable_login_button(self):
        # Return True to show the "Login with existing account" button
        return True
