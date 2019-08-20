class disable_drrs_conditionally {
  file {
    [ '/etc/systemd/system/multi-user.target.wants/puavo-maybe-disable-drrs.service',
      '/etc/systemd/system/sleep.target.wants/puavo-maybe-disable-drrs.service' ]:
      ensure  => link,
      require => File['/etc/systemd/system/puavo-maybe-disable-drrs.service'],
      target  => '/etc/systemd/system/puavo-maybe-disable-drrs.service';

    '/etc/systemd/system/puavo-maybe-disable-drrs.service':
      require => File['/usr/local/lib/puavo-maybe-disable-drrs'],
      source  => 'puppet:///modules/disable_drrs_conditionally/puavo-maybe-disable-drrs.service';

    '/usr/local/lib/puavo-maybe-disable-drrs':
      mode   => '0755',
      source => 'puppet:///modules/disable_drrs_conditionally/puavo-maybe-disable-drrs';
  }
}
