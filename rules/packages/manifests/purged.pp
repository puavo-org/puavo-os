class packages::purged {
  require packages      # install packages first, then purge

  # purge packages by default
  Package { ensure => purged, }

  @package {
    [ 'cups-pk-helper'		# we do not need this, and it has bugs

    # slows down login considerably
    # (runs dpkg-query without speed considerations)
    , 'im-config'

    , 'lilypond-doc'
    , 'lilypond-doc-html'
    , 'lilypond-doc-pdf'

    , 'linux-image-generic'             # we want to choose kernels explicitly

    , 'samba'				# not needed, gets into system as
					# some recommendation through winbind

    # the functionality in these is not for our end users
    , 'software-properties-gtk'
    , 'synaptic'

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

    , 'tracker' ]:              # this uses too much resources when using nfs
      tag => [ 'ubuntu', ];
  }
}
