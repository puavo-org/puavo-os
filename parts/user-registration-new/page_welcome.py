# The "Welcome" page

import gettext

from page_definition import PageDefinition

_tr = gettext.gettext


class PageWelcome(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir):
        super().__init__(application, parent_window, parent_container, data_dir)

        self.load_file('welcome.glade', 'welcome_texts')

        self.builder.get_object('welcome_title').set_markup(_tr('Tervetuloa!'))

        self.builder.get_object('welcome_text').set_markup(_tr('\n' \
'Uuden kannettavasi käyttöönottamiseksi, sinut opastetaan seuraavaksi:\n\n' \
'\t<span color="#0f0"><big>1.</big></span> Liittymään langattomaan verkkoon\n' \
'\t<span color="#0f0"><big>2.</big></span> Rekisteröimään itsellesi uusi käyttäjätunnus\n\n'))

        self.builder.get_object('welcome_footer').set_markup( \
_tr('<span color="#0f0">Vinkki:</span> Mikäli et pysty liittämään kannettavaa verkkoon juuri nyt, ' \
'voit tehdä sen myös\nmyöhemminja käyttää konetta tilapäisesti vieras-tilassa napsauttamalla ' \
'alareunassa\nolevaa <i>"Siirry työpöydälle"</i> -painiketta.'))

        self.builder.get_object('welcome_next').connect('clicked', self.welcome_next_clicked)


    def welcome_next_clicked(self, *args):
        self.application.next_page()
