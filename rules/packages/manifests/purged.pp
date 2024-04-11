class packages::purged {
  require packages      # install packages first, then purge

  # purge packages by default
  Package { ensure => purged, }

  exec {
    # Breaks UEFI Grub.  We need a solution to
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=959425
    # before we can allow grub-efi-amd64-signed to be installed.
    'force remove grub-efi-amd64-signed':
      command => '/usr/bin/apt-get -y --allow-remove-essential purge grub-efi-amd64-signed',
      onlyif  => '/usr/bin/test -e /var/lib/dpkg/info/grub-efi-amd64-signed.list';
  }

  @package {
    [ 'asymptote-doc'           # asymptote not included in menus or anywhere, docs bigger than the main package
    , 'bzip2-doc'               # API docs, algorithm description, not needed in image
    , 'denemo-doc'              # denemo not included in menu, doc bigger than the main package, doesn't seem to open from denemo UI
    , 'exim4-base'              # we do not need an MTA
    , 'exim4-config'
    , 'exim4-daemon-light'

    , 'firefox-esr'             # we are using the latest Firefox
    , 'ghc'                     # takes too much space
    , 'gnome-screensaver'       # not using this for anything

    # slows down login considerably
    # (runs dpkg-query without speed considerations)
    , 'im-config'

    # various HTML api docs. not quite needed in image
    , 'libglib2.0-doc'
    , 'libgtk-3-doc'
    , 'nodejs-doc'

    , 'lilypond-doc'
    , 'lilypond-doc-html'
    , 'lilypond-doc-pdf'

    , 'linux-image-generic'             # we want to choose kernels explicitly

    , 'needrestart'     # no need for this when using image-based system

    # the functionality in these is not for our end users
    , 'mercurial'
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
