# The "Welcome" page

import gettext

from logger import log

from page_definition import PageDefinition

gettext.bindtextdomain('puavo-user-registration', '/usr/share/locale')
gettext.textdomain('puavo-user-registration')
_tr = gettext.gettext


class PageComplete(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir, main_builder):
        super().__init__(application, parent_window, parent_container, data_dir, main_builder)

        self.account_created = False

        self.load_file('complete.glade', 'complete_texts')

        self.builder.get_object('complete_title').set_markup(_tr('Congratulations!'))

        self.builder.get_object('complete_reboot').connect('clicked', self.reboot_clicked)


    def set_account_created(self):
        self.account_created = True


    def activate(self):
        if self.account_created:
            status_text = _tr('Your user account has been created.')
        else:
            status_text = _tr('Login with your user account was successful.')

        text = status_text + '  ' \
                 + _tr('Have a nice time with your studies!') + '\n\n' \
                 + _tr('System must be rebooted.')

        self.builder.get_object('complete_text').set_markup(text)

        super().activate()

        self.application.finish_registration()


    def enable_desktop_button(self):
        return False


    def reboot_clicked(self, *args):
        self.application.reboot()
