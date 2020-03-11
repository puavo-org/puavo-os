class packages::purged {
  require packages      # install packages first, then purge

  # purge packages by default
  Package { ensure => purged, }

  @package {
    [ 'exim4-base'              # we do not need an MTA
    , 'exim4-config',
    , 'exim4-daemon-light'

    , 'firefox-esr'             # we are using the latest Firefox
    , 'ghc'                     # takes too much space
    , 'gnome-screensaver'       # not using this for anything

    # slows down login considerably
    # (runs dpkg-query without speed considerations)
    , 'im-config'

    , 'lilypond-doc'
    , 'lilypond-doc-html'
    , 'lilypond-doc-pdf'

    , 'linux-image-generic'             # we want to choose kernels explicitly

    , 'racket-doc'                      # takes too much space

    # the functionality in these is not for our end users
    , 'software-properties-gtk'
    , 'synaptic'

    , 'texlive-fonts-extra'
    , 'texlive-fonts-extra-doc'
    , 'texlive-fonts-recommended-doc'
    , 'texlive-latex-base-doc'
    , 'texlive-latex-extra-doc'
    , 'texlive-latex-recommended-doc'
    , 'texlive-pictures-doc'
    , 'texlive-pstricks-doc'

    , 'tftpd-hpa'               # this is suggested by ltsp-server, but
                                # we do not actually use tftpd on ltsp-server
                                # (we use a separate boot server)

    , 'wx3.0-doc' ]:
      tag => [ 'tag_debian_desktop' ];
  }
}
