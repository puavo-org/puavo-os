class gdm {
  include ::packages
  include ::puavo_conf

  ::puavo_conf::script {
    'xsessions_lock':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/gdm/xsessions_lock';
  }

  Package <| title == puavo-ltsp-client |>
}
