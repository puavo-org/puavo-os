class packages::languages::de {
  @package {
    [ 'hunspell-de-ch'
    , 'hunspell-de-de'
    , 'hyphen-de'
    # , 'kde-l10n-de'           # XXX missing from Bullseye
    , 'libreoffice-help-de'
    , 'libreoffice-l10n-de'
    , 'mythes-de'
    , 'mythes-de-ch'
    , 'thunderbird-l10n-de' ]:
      tag => [ 'tag_debian_desktop', 'tag_language_de', ];
  }
}
