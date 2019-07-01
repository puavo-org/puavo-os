# The "Welcome" page

import gettext

from page_definition import PageDefinition

_tr = gettext.gettext


class PageComplete(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir):
        super().__init__(application, parent_window, parent_container, data_dir)

        self.load_file('complete.glade', 'complete_texts')

        self.builder.get_object('complete_title').set_markup(_tr('Onneksi olkoon!'))

        self.builder.get_object('complete_text').set_markup( \
            _tr('Käyttäjätunnuksesi on luotu. Onnea opintojesi pariin!') +
            '\n\n' +
            _tr('Järjestelmä on käynnistettävä uudelleen yhden kerran, jotta ' \
                'asennusprosessi\nvoidaan viimeistellä. Paina allaolevaa nappia, ' \
                'kun olet valmis.'))

        self.builder.get_object('complete_reboot').connect('clicked', self.reboot_clicked)


    def enable_desktop_button(self):
        return False


    def reboot_clicked(self, *args):
        self.application.finish_registration()
