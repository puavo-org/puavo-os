class packages::purged {
  require packages      # install packages first, then purge

  # purge packages by default
  Package { ensure => purged, }

  @package {
    # we use webmenu for logouts and such, indicator-session is not needed
    [ 'indicator-session'

    # the functionality in these is not for our end users
    , 'software-properties-gtk'
    , 'synaptic'
    , 'ubuntu-release-upgrader-gtk'
    , 'update-manager'
    , 'update-notifier'

    , 'tftpd-hpa'               # this is suggested by ltsp-server, but
                                # we do not actually use tftpd on ltsp-server
                                # (we use a separate boot server)

    , 'tracker'                 # this uses too much resources when using nfs
    , 'zram-config' ]:          # zram triggers bugs in 3.6.6 and probably some
                                # other kernels as well
      tag => [ 'ubuntu', ];
  }
}
