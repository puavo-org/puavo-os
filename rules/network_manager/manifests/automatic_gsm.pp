class network_manager::automatic_gsm {
  include ::packages

  file {
    '/etc/systemd/system/multi-user.target.wants/puavo-generate-gsm-config-for-nm.service':
      ensure  => link,
      require => [ File['/etc/systemd/system/puavo-generate-gsm-config-for-nm.service']
                 , Package['systemd'] ],
      target  => '/etc/systemd/system/puavo-generate-gsm-config-for-nm.service';

    '/etc/systemd/system/puavo-generate-gsm-config-for-nm.service':
      require => [ File['/usr/local/lib/puavo-generate-gsm-config-for-nm']
                 , Package['systemd'] ],
      source  => 'puppet:///modules/network_manager/puavo-generate-gsm-config-for-nm.service';

    '/usr/local/lib/puavo-generate-gsm-config-for-nm':
      mode   => '0755',
      source => 'puppet:///modules/network_manager/puavo-generate-gsm-config-for-nm';
  }

  Package <| title == systemd |>
}
