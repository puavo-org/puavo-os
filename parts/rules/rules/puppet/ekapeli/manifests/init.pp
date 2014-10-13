class ekapeli {
  include packages

  file {
    '/etc/fuse.conf':
      group   => 'fuse',
      mode    => 640,
      require => Package['fuse'],
      source  => 'puppet:///modules/ekapeli/fuse.conf';

    '/usr/local/bin/ekapeli':
      mode    => 755,
      require => File['/usr/local/lib/ekapeli/ekapeli_wrapper'],
      source  => 'puppet:///modules/ekapeli/ekapeli';

    '/usr/local/lib/ekapeli':
      ensure => directory;

    '/usr/local/lib/ekapeli/ekapeli_wrapper':
      mode    => 755,
      require => [ File['/etc/fuse.conf']
                 , Package['bindfs']
                 , Package['ekapeli']
                 , Package['oracle-java']
                 , Package['unionfs-fuse'] ],
      source  => 'puppet:///modules/ekapeli/ekapeli_wrapper';

    '/usr/local/share/applications/ekapeli.desktop':
      require => [ File['/usr/local/bin/ekapeli']
                 , Package['faenza-icon-theme'] ],
      source  => 'puppet:///modules/ekapeli/ekapeli.desktop';
  }

  Package <| title == bindfs
          or title == ekapeli
          or title == faenza-icon-theme
          or title == fuse
          or title == oracle-java
          or title == unionfs-fuse |>
}
