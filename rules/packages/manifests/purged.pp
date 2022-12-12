class packages::purged {
  require packages      # install packages first, then purge

  # purge packages by default
  Package { ensure => purged, }

  @package {
    [ 'exim4-base'              # we do not need an MTA
    , 'exim4-config'
    , 'exim4-daemon-light'

    , 'firefox-esr'             # we are using the latest Firefox
    , 'ghc'                     # takes too much space
    , 'gnome-screensaver'       # not using this for anything

    , 'grub-efi-amd64-signed'   # breaks UEFI Grub

    # slows down login considerably
    # (runs dpkg-query without speed considerations)
    , 'im-config'

    , 'lilypond-doc'
    , 'lilypond-doc-html'
    , 'lilypond-doc-pdf'

    , 'linux-image-generic'             # we want to choose kernels explicitly

    # no Python 2
    , 'libpython2.7-minimal'
    , 'libpython2.7-stdlib'
    , 'libpython2-stdlib'
    , 'python2'
    , 'python2.7'
    , 'python2.7-minimal'
    , 'python2-minimal'
    , 'python-is-python2'

    # the functionality in these is not for our end users
    , 'software-properties-gtk'
    , 'synaptic'

    , 'texlive-fonts-extra'
    , 'texlive-fonts-extra-doc'
    , 'texlive-fonts-recommended-doc'
    , 'texlive-lang-english'     #seems actually to be only documentation
    , 'texlive-latex-base-doc'
    , 'texlive-latex-extra-doc'
    , 'texlive-latex-recommended-doc'
    , 'texlive-pictures-doc'
    , 'texlive-pstricks-doc'

    , 'tftpd-hpa'

    , 'wx3.0-doc'

    # Do not include "xbrlapi", we probably do not need it.
    # In /etc/X11/Xsession.d/90xbrlapi it tries to connect to
    # brltty, but if it not installed (installing "brltty" package
    # is sufficient), it tries to connect to it (port 4101) through
    # IPv4 and IPv6.  The first returns ECONNREFUSED and the latter
    # returns ETIMEDOUT after some 160 seconds (which may depend on
    # other network-related factors).
    , 'xbrlapi' ]:
      tag => [ 'tag_debian_desktop' ];
  }
}
