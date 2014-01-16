class open-sankore {
  include packages

  file {
    '/usr/local/Open-Sankore-2.1.0/i18n/sankore_fi.qm':
      content => template('open-sankore/sankore_fi.qm'),
      require => Package['open-sankore'];
  }

  Package <| title == open-sankore |>
}
