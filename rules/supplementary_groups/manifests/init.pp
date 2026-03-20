class supplementary_groups {
  include ::packages

  $groups = [ 'audio'
            , 'bluetooth'
            , 'cdrom'
            , 'dialout'
            , 'dip'
            , 'floppy'
            , 'lp'
            , 'netdev'
            , 'plugdev'
            , 'puavodesktop'
            , 'scanner'
            , 'users'
            , 'vboxusers'
            , 'video' ]

  #
  # add users to supplementary groups via pam_group / systemd -tricks
  #

  file {
    '/etc/security/group.conf':
      content => template('supplementary_groups/group.conf'),
      require => Package['libpam-modules'];

    '/etc/systemd/system/user@.service.d':
      ensure  => directory,
      require => Package['systemd'];

    '/etc/systemd/system/user@.service.d/override.conf':
      content => template('supplementary_groups/user@.service.d_override.conf'),
      require => Package['systemd'];
  }

  Package <|
       title == libpam-modules
    or title == systemd
  |>
}
