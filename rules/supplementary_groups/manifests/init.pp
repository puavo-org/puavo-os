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
  # add users to supplementary groups via pam_group
  #

  file {
    '/etc/security/group.conf':
      content => template('supplementary_groups/group.conf'),
      require => Package['libpam-modules'];
  }

  Package <| title == libpam-modules |>
}
