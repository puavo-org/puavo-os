class puavolocalconfigui {
  include packages

  file {
    '/etc/puavo-local-config/puavo-local-config-ui.conf':
      require => Package['puavo-local-config'];
  }

  Package <| title == puavo-local-config |>
}
