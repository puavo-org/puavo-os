class disable_suspend_by_tag {
  include initramfs,
          packages

  file {
    '/etc/pm/sleep.d/02_nosuspendtag_test':
      mode    => 755,
      require => Package['pm-utils'],
      source  => 'puppet:///modules/disable_suspend_by_tag/02_nosuspendtag_test';

    '/usr/share/puavo-conf/definitions/puavo-rules-disable_suspend_by_tag.json':
      notify  => Exec['initramfs::update'],
      require => Package['puavo-conf'],
      source  => 'puppet:///modules/disable_suspend_by_tag/puavo-conf-parameters.json';
  }

  Package <| title == pm-utils
          or title == puavo-conf |>
}
