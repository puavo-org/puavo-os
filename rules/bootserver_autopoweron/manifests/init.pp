class bootserver_autopoweron {
  include ::packages

  file {
    '/etc/cron.d/puavo-autopoweron':
      content => template('bootserver_autopoweron/puavo-autopoweron.cron'),
      mode    => '0644',
      require => File['/etc/systemd/system/puavo-autopoweron.service'];

    '/etc/systemd/system/puavo-autopoweron.service':
      content => template('bootserver_autopoweron/puavo-autopoweron.service'),
      mode    => '0644',
      require => File['/usr/local/lib/puavo-autopoweron'];

    '/usr/local/lib/puavo-autopoweron':
      content => template('bootserver_autopoweron/puavo-autopoweron'),
      mode    => '0755',
      require => Package['wakeonlan'];
  }

  Package <| title == moreutils or title == wakeonlan |>
}
