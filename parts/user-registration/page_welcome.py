# The "Welcome" page

import gettext

from page_definition import PageDefinition

gettext.bindtextdomain('puavo-user-registration', '/usr/share/locale')
gettext.textdomain('puavo-user-registration')
_tr = gettext.gettext


class PageWelcome(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir):
        super().__init__(application, parent_window, parent_container, data_dir)

        self.load_file('welcome.glade', 'welcome_texts')

        self.builder.get_object('welcome_title').set_markup(_tr('Welcome!'))

        self.builder.get_object('welcome_text').set_markup('\n' \
          + _tr('To put your new laptop into use, we guide you to:') \
          + '\n\n\t<span color="#0f0"><big>1.</big></span>' \
          + _tr('Join a wireless network') \
          + '\n\t<span color="#0f0"><big>2.</big></span>' \
          + _tr('Register your new login') + '\n\n')

        self.builder.get_object('welcome_footer').set_markup( \
          '<span color="#0f0">' + _tr('Tip:') + '</span>' \
            + _tr('In case you can not connect to a wireless network right now, '
                  'you can do that later and use this host temporarily in ' \
                  'guest-mode by clicking the') \
            + '<i>"' + _tr('Go to desktop') + '"</i>-' \
            + _tr('button in the bottom corner.') \
            + '  ' + _tr('If you already have an account, choose') \
            + ' ' + '<i>"' + _tr('Login with existing account') + '"</i>.')

        self.builder.get_object('welcome_next').connect('clicked', self.welcome_next_clicked)


    def welcome_next_clicked(self, *args):
        self.application.next_page()
