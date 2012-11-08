class packages {
  $packages = [ 'bridge-utils'
              , 'btrfs-tools'
              , 'gimp'
              , 'git'
              , 'ltsp-client'
              , 'ltsp-server'
              , 'lvm2'
              , 'nfs-common'
              , 'openssh-client'
              , 'openssh-server'
              , 'sudo'
              , 'tmux'
              , 'tshark'
              , 'ubuntu-gnome-desktop'
              , 'ubuntu-restricted-extras'
              , 'ubuntu-standard'
              , 'vlan' ]

  @package {
    $packages:
      ensure => present;
  }
}
