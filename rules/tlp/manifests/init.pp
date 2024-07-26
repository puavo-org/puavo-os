class tlp {
  include ::packages

  file {
    '/etc/tlp.conf':
      ensure  => present,
      mode    => '0644',
      require => Package['tlp'],
      source  => 'puppet:///modules/tlp/tlp.conf';
  }

  Package <| title == tlp |>
}
