# The "Login" page

import gettext

from page_definition import PageDefinition

gettext.bindtextdomain('puavo-user-registration', '/usr/share/locale')
gettext.textdomain('puavo-user-registration')
_tr = gettext.gettext


class PageLogin(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir):
        super().__init__(application, parent_window, parent_container, data_dir)

        self.load_file('login.glade', 'login')


    def enable_desktop_button(self):
        return False
