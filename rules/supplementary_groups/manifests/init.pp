class supplementary_groups {
  include ::packages

  $groups = [ 'bluetooth'
            , 'cdrom'
            , 'dialout'
            , 'floppy'
            , 'lp'
            , 'plugdev'
            , 'puavodesktop'
            , 'scanner'
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
