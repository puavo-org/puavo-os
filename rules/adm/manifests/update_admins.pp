class adm::update_admins {
  file {
    '/etc/systemd/system/multi-user.target.wants/puavo-update-admins.service':
      ensure  => link,
      require => File['/etc/systemd/system/puavo-update-admins.service'],
      target  => '/etc/systemd/system/puavo-update-admins.service';

    '/etc/systemd/system/puavo-update-admins.service':
      require => File['/usr/local/sbin/puavo-update-admins'],
      source  => 'puppet:///modules/adm/puavo-update-admins.service';

    '/usr/local/sbin/puavo-update-admins':
      mode   => '0755',
      source => 'puppet:///modules/adm/puavo-update-admins';
  }
}
