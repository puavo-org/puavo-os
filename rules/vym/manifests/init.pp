class vym {
  include ::packages

  # Vym complains of missing Finnish translation,
  # we know and we are okay with the English version.
  file {
    '/usr/share/vym/lang/vym.fi.qm':
      ensure  => link,
      require => Package['vym'],
      target  => 'vym.en.qm';
  }

  Package <| title == vym |>
}
