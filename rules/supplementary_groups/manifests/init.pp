class supplementary_groups {
  include ::packages

  $groups = [ 'bluebooth'
            , 'cdrom'
            , 'dialout'
            , 'floppy'
            , 'lp'
            , 'lpadmin'
            , 'plugdev'
            , 'puavodesktop'
            , 'scanner'
            , 'video' ]

  #
  # add users to supplementary groups via pam_group / systemd -tricks
  #

  file {
    '/etc/security/group.conf':
      content => template('supplementary_groups/group.conf'),
      require => Package['libpam-modules'];

    '/etc/systemd/system/user@.service.d':
      ensure => directory;

    '/etc/systemd/system/user@.service.d/override.conf':
      content => template('supplementary_groups/user@.service.d_override.conf'),
      require => Package['systemd'];
  }

  Package <|
       title == libpam-modules
    or title == systemd
  |>
}
