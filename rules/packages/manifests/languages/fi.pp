class packages::languages::fi {
  @package {
    [ 'firefox-esr-l10n-fi:i386'
    , 'icedove-l10n-fi'
    , 'kde-l10n-fi'
    , 'libreoffice-help-fi'
    , 'libreoffice-l10n-fi'
    , 'libreoffice-voikko' ]:
      tag => [ 'tag_debian_desktop', 'tag_language_fi', ];
  }
}
