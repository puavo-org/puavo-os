class gdm {
  include ::packages
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_xsessions':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/gdm/setup_xsessions';
  }

  Package <| title == puavo-ltsp-client |>
}
