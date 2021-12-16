class veyon {
  include ::packages
  include ::puavo_conf

  file {
    '/usr/local/bin/veyon-vnc':
      mode    => '0755',
      require => Package['x11vnc'],
      source  => 'puppet:///modules/veyon/veyon-vnc';
  }

  ::puavo_conf::script {
    'setup_veyon':
      source => 'puppet:///modules/veyon/setup_veyon';
  }

  Package <| title == "x11vnc" |>
}
