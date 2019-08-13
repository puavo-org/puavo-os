# All strings in one file for easy translation. No need to slowly parse
# configuration files for something that practically never changes.

STRINGS = {
    # --------------------------------------------------------------------------
    # Main window

    'search_placeholder': {
        'fi': 'Etsi...',
        'en': 'Search...',
        'sv': 'Sök...',
        'de': 'Suchen...',
    },

    'search_no_results': {
        'fi': 'Ei osumia',
        'en': 'No hits',
        'de': 'Keine Resultate',
    },

    'menu_empty_menu': {
        'fi': 'Tyhjä valikko',
        'en': 'Empty menu',
        'de': 'Leeres Menu',
    },

    'menu_empty_category': {
        'fi': 'Tyhjä kategoria',
        'en': 'Empty category',
        'de': 'Leere Kategorie',
    },

    # Development mode
    'menu_no_data_at_all_dev': {
        'fi': 'Ei valikkodataa? Tarkista tilanne!',
        'en': 'No menu data? Check the situation!',
        'de': 'Kein Menu? Was ist hier los!',
    },

    # Longer text in production mode
    'menu_no_data_at_all_prod': {
        'fi': 'Valikon lataus ei onnistunut :-(\n\n' \
              'Kokeile kirjautua sisään uudelleen.\n' \
              'Jos se ei auta, käynnistä kone uudelleen.\n' \
              'Jos sekään ei auta, ole hyvä ja ota yhteys tukeen.',

        'en': 'Menu loading did not succeed :-(\n\n' \
              'Try logging out and back in again.\n' \
              'If that does not help, try restarting the computer.\n' \
              'If even that does not help, please contact support.',

        'de': 'Das Menu konnte nicht geladen werden :-(\n\n' \
              'Versuche dich abzumelden und wieder anzumelden.\n' \
              'Wenn das nicht hilft, starte den Computer neu.\n' \
              'Wenn das nicht hilft, wende dich an den Support.',
    },

    'desktop_link_failed': {
        'en': 'Desktop link could not be created',
        'fi': 'Työpöytäkuvaketta ei voitu luoda',
        'de': 'Desktoplink konnte nicht erstellt werden',
    },

    'panel_link_failed': {
        'en': 'Panel icon could not be created',
        'fi': 'Paneelin kuvaketta ei voitu luoda',
        'de': 'Panelicon konnte nicht erstellt werden',
    },

    'program_launching_failed': {
        'en': 'Could not launch a program',
        'fi': 'Ohjelmaa ei voitu käynnistää',
        'de': 'Programm konnte nicht geöffnet werden',
    },

    # --------------------------------------------------------------------------
    # Buttons

    # This must be *SHORT* as it must fit below the normal icon text!
    'button_puavopkg_installer_suffix': {
        'en': 'installer',
        'fi': 'asennin',
        'sv': 'installer',
        'de': 'Installateur',
    },

    'button_puavopkg_installer_tooltip': {
        'en': 'Click to install this program',
        'fi': 'Klikkaa asentaaksesi tämä ohjelma',
        'sv': 'Klicka för att installera det här programmet',
        'de': 'Klicken Sie hier, um dieses Programm zu installieren',
    },

    # --------------------------------------------------------------------------
    # Sidebar

    'sb_avatar_hover': {
        'en': 'Edit your user profile',
        'fi': 'Muokkaa käyttäjäprofiiliasi',
        'de': 'Ediere Benutzerprofil'
    },

    'sb_avatar_link_failed': {
        'en': 'Could not open the user preferences editor',
        'fi': 'Ei voitu avata käyttäjätietojen muokkausta',
        'de': 'Konnte den Benutzerprofil-Editor nicht öffnen',
    },

    'sb_button_failed': {
        'en': 'Sidebar button action failed',
        'fi': 'Sivupaneelin napin toiminnon suoritus ei onnistunut',
        'de': 'Seitenleisten-Aktion konnte nicht ausgeführt werden',
    },

    'sb_change_password': {
        'en': 'Change password',
        'fi': 'Vaihda salasana',
        'sv': 'Byta lösenord',
        'de': 'Setze ein neues Passwort'
    },

    'sb_change_password_window_title': {
        'en': 'Change password',
        'fi': 'Vaihda salasana',
        'sv': 'Byta lösenord',
        'de': 'Setze ein neues Passwort',
    },

    'sb_laptop_setup': {
        'en': 'Laptop setup',
        'fi': 'Kannettavan asetukset',
        'sv': 'Laptop inställning',
        'de': 'Laptop-Setup',
    },

    'sb_puavopkg_installer': {
        'en': 'Additional software installation',
        'fi': 'Lisäohjelmistojen asennus',
        'sv': 'Ytterligare programinstallation',
        'de': 'Zusätzliche Softwareinstallation',
    },

    'sb_support': {
        'en': 'Support',
        'fi': 'Tukisivusto',
        'sv': 'Stöd',
        'de': 'Support',
    },

    'sb_system_settings': {
        'en': 'System settings',
        'fi': 'Järjestelmän asetukset',
        'sv': 'Systeminställningar',
        'de': 'Systemeinstellungen',
    },

    'sb_lock_screen': {
        'en': 'Lock screen',
        'fi': 'Lukitse näyttö',
        'sv': 'Lås skärmen',
        'de': 'Bildschirm sperren',
    },

    'sb_hibernate': {
        'en': 'Sleep',
        'fi': 'Unitila',
        'sv': 'Strömsparläge',
        'de': 'Schlafen'
    },

    'sb_logout': {
        'en': 'Logout',
        'fi': 'Kirjaudu ulos',
        'sv': 'Logga ut',
        'de': 'Abmelden',
    },

    'sb_restart': {
        'en': 'Restart',
        'fi': 'Käynnistä uudelleen',
        'sv': 'Starta om',
        'de': 'Neustarten',
    },

    'sb_shutdown': {
        'en': 'Shut down',
        'fi': 'Sammuta',
        'sv': 'Stäng av',
        'de': 'Herunterfahren',
    },

    'sb_changelog_title': {
        'en': 'Show changes in this version',
        'fi': 'Näytä muutokset tässä versiossa',
        'de': 'Zeige Änderungen dieser Version',
    },

    'sb_changelog_window_title': {
        'en': 'Changelog',
        'fi': 'Muutosloki',
        'de': 'Changelog',
    },

    'sb_changelog_link_failed': {
        'en': 'Could not show the changelog',
        'fi': 'Muutoslokin näyttäminen ei onnistunut',
        'de': 'Changelog kann nicht angezeigt werden',
    },

    # --------------------------------------------------------------------------
    # Popup menus

    'popup_add_to_desktop': {
        'fi': 'Lisää työpöydälle',
        'en': 'Add to desktop',
        'sv': 'Lägg till på skrivbordet',
        'de': 'Füge zum Schreibtisch hinzu',
    },

    'popup_add_to_panel': {
        'fi': 'Lisää alapaneeliin',
        'en': 'Add to bottom panel',
        'sv': 'Lägg till i panel',
        'de': 'Füge der unteren Leiste hinzu',
    },

    'popup_remove_from_faves': {
        'fi': 'Poista suosikeista',
        'en': 'Remove from favorites',
        'sv': 'Ta bort från favoriter',
        'de': 'Entferne Lesezeichen',
    },
}
