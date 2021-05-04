class packages::languages::fi {
  @package {
    # [ 'kde-l10n-fi'           # XXX missing from Bullseye
    [ 'libreoffice-help-fi'
    , 'libreoffice-l10n-fi'
    , 'libreoffice-voikko'
    , 'thunderbird-l10n-fi' ]:
      tag => [ 'tag_debian_desktop', 'tag_language_fi', ];
  }
}
