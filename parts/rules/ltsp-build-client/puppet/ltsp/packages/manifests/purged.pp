class packages::purged {
  require packages      # install packages first, then purge

  # purge packages by default
  Package { ensure => purged, }

  @package {
    # the functionality in these is not for our end users
    [ 'gnome-media'			# broken software

    # slows down login considerably
    # (runs dpkg-query without speed considerations)
    , 'im-config'

    , 'linux-image-generic'             # we want to choose kernels explicitly

    , 'samba'				# not needed, gets into system as
					# some recommendation through winbind

    , 'software-properties-gtk'
    , 'synaptic'
    , 'ubuntu-release-upgrader-core'

    , 'tftpd-hpa'               # this is suggested by ltsp-server, but
                                # we do not actually use tftpd on ltsp-server
                                # (we use a separate boot server)

    , 'tracker' ]:              # this uses too much resources when using nfs
      tag => [ 'ubuntu', ];
  }
}
