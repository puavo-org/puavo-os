# The "Welcome" page

import gettext

from page_definition import PageDefinition

gettext.bindtextdomain('puavo-user-registration', '/usr/share/locale')
gettext.textdomain('puavo-user-registration')
_tr = gettext.gettext


class PageComplete(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir):
        super().__init__(application, parent_window, parent_container, data_dir)

        self.load_file('complete.glade', 'complete_texts')

        self.builder.get_object('complete_title').set_markup(_tr('Congratulations!'))

        self.builder.get_object('complete_text').set_markup( \
            _tr('Your user account has been created.') \
              + '  ' + _tr('Have a nice time with your studies!') +
            '\n\n' +
            _tr('System must be rebooted, press OK when ready!'))

        self.builder.get_object('complete_reboot').connect('clicked', self.reboot_clicked)


    def enable_desktop_button(self):
        return False


    def reboot_clicked(self, *args):
        self.application.finish_registration()
