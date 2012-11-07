class packages {
  $packages = [ 'bridge-utils'
              , 'btrfs-tools'
              , 'gimp'
              , 'ltsp-client'
              , 'ltsp-server'
              , 'lvm2'
              , 'nfs-common'
              , 'openssh-server'
              , 'tmux'
              , 'tshark'
              , 'ubuntu-gnome-desktop'
              , 'ubuntu-restricted-extras'
              , 'ubuntu-standard'
              , 'vlan' ]

  package {
    $packages:
      ensure => present;
  }
}
