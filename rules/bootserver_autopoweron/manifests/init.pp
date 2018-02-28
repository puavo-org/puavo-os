class bootserver_autopoweron {
  include ::packages

  file {
    '/etc/cron.d/puavo-autopoweron':
      content => template('bootserver_autopoweron/puavo-autopoweron.cron'),
      mode    => '0644',
      require => File['/etc/systemd/system/puavo-autopoweron.service'];

    # XXX This should be controlled by puavo.service.puavo-autopoweron.enabled
    # XXX puavo-conf variable, I suppose.
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
