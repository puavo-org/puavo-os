class packages::languages::sv {
  @package {
    [ 'hunspell-sv-se'
    # , 'kde-l10n-sv'           # XXX missing from Bullseye
    , 'libreoffice-help-sv'
    , 'libreoffice-l10n-sv'
    , 'mythes-sv'
    , 'thunderbird-l10n-sv-se' ]:
      tag => [ 'tag_debian_desktop', 'tag_language_sv', ];
  }
}
