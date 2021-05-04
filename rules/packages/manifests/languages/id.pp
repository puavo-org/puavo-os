class packages::languages::id {
  @package {
    [ 'hyphen-id'
    # , 'kde-l10n-id'           # XXX missing from Bullseye
    , 'libreoffice-l10n-id'
    , 'hunspell-id'
    , 'mythes-id'
    , 'thunderbird-l10n-id' ]:
      tag => [ 'tag_debian_desktop', 'tag_language_id', ];
  }
}
