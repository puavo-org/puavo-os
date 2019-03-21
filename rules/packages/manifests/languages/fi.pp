class packages::languages::fi {
  @package {
    [ 'firefox-esr-l10n-fi'
    , 'kde-l10n-fi'
    , 'libreoffice-help-fi'
    , 'libreoffice-l10n-fi'
    , 'libreoffice-voikko'
    , 'thunderbird-l10n-fi' ]:
      tag => [ 'tag_debian_desktop', 'tag_language_fi', ];
  }
}
