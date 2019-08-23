class disable_drrs_conditionally {
  file {
    '/etc/systemd/system/multi-user.target.wants/puavo-maybe-disable-drrs.service':
      ensure  => link,
      require => File['/etc/systemd/system/puavo-maybe-disable-drrs.service'],
      target  => '/etc/systemd/system/puavo-maybe-disable-drrs.service';

    '/etc/systemd/system/puavo-maybe-disable-drrs.service':
      require => File['/usr/local/lib/puavo-maybe-disable-drrs'],
      source  => 'puppet:///modules/disable_drrs_conditionally/puavo-maybe-disable-drrs.service';

    '/lib/systemd/system-sleep/puavo-maybe-disable-drrs':
      mode   => '0755',
      source => 'puppet:///modules/disable_drrs_conditionally/lib_systemd_system-sleep_puavo-maybe-disable-drrs';

    '/usr/local/lib/puavo-maybe-disable-drrs':
      mode   => '0755',
      source => 'puppet:///modules/disable_drrs_conditionally/puavo-maybe-disable-drrs';
  }
}
