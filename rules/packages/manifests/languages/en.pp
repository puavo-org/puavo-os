class packages::languages::en {
  @package {
    [ 'hunspell-en-gb'
    , 'hyphen-en-us'
    # , 'kde-l10n-engb'         # XXX missing from Bullseye
    , 'libreoffice-help-en-gb'
    , 'libreoffice-l10n-en-gb'
    , 'libreoffice-l10n-en-za'
    , 'mythes-en-us'
    , 'thunderbird-l10n-en-gb' ]:
      tag => [ 'tag_debian_desktop', 'tag_language_en', ];
  }
}
