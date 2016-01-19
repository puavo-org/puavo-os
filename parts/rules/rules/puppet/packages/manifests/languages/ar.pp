class packages::languages::ar {
  @package {
    [ 'language-pack-ar' ]:
      tag => [ 'language-ar', 'thinclient', 'ubuntu', ];

    [ 'aspell-ar-large'
    , 'firefox-locale-ar'
    , 'hunspell-ar'
    , 'kde-l10n-ar'
    , 'language-pack-gnome-ar'
    , 'language-pack-kde-ar'
    , 'libreoffice-l10n-ar'
    , 'thunderbird-locale-ar' ]:
      tag => [ 'language-ar', 'ubuntu', ];

    # XXX ?
    [ 'othman'
    , 'tesseract-ocr-ara'
    , 'thawab'
    , 'ubuntu-keyboard-arabic'
    , 'texlive-lang-arabic'
    , 'xfonts-intl-arabic'
    ]: tag => [ 'language-ar', 'ubuntu', ];
  }
}
