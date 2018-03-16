class bootserver_autopoweron {
  include ::packages

  file {
    '/usr/local/lib/puavo-autopoweron':
      content => template('bootserver_autopoweron/puavo-autopoweron'),
      mode    => '0755',
      require => Package['wakeonlan'];
  }

  Package <| title == wakeonlan |>
}
