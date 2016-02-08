class packages::languages::ar {
  @package {
    [ 'aspell-ar-large'
    , 'hunspell-ar'
    , 'icedove-l10n-ar'
    , 'iceweasel-l10n-ar'
    , 'kde-l10n-ar'
    , 'libreoffice-l10n-ar' ]:
      tag => [ 'language-ar', 'ubuntu', ];

    # XXX ?
    [ 'othman'
    , 'tesseract-ocr-ara'
    , 'thawab'
    , 'texlive-lang-arabic'
    , 'xfonts-intl-arabic'
    ]: tag => [ 'language-ar', 'ubuntu', ];
  }
}
