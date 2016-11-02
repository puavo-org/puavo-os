class zram_configuration {
  # These configurations are mostly copied from the Ubuntu "zram-config"
  # package.

  file {
    '/etc/systemd/system/multi-user.target.wants/zram-config.service':
      ensure  => link,
      require => File['/etc/systemd/system/zram-config.service'],
      target  => '/etc/systemd/system/zram-config.service';

    '/etc/systemd/system/zram-config.service':
      require => [ File['/usr/local/bin/end-zram-swapping']
                 , File['/usr/local/bin/init-zram-swapping'] ],
      source  => 'puppet:///modules/zram_configuration/zram-config.service';

    '/usr/local/bin/end-zram-swapping':
      mode   => '0755',
      source => 'puppet:///modules/zram_configuration/end-zram-swapping';

    '/usr/local/bin/init-zram-swapping':
      mode   => '0755',
      source => 'puppet:///modules/zram_configuration/init-zram-swapping';
  }
}
