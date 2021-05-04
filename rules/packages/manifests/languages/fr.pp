class packages::languages::fr {
  @package {
    [ 'hunspell-fr'
    , 'hyphen-fr'
    # , 'kde-l10n-fr'           # XXX missing from Bullseye
    , 'libreoffice-help-fr'
    , 'libreoffice-l10n-fr'
    , 'mythes-fr'
    , 'thunderbird-l10n-fr' ]:
      tag => [ 'tag_debian_desktop', 'tag_language_fr', ];
  }
}
