class gdm {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/gdm3/daemon.conf':
      require => Package['gdm3'],
      source  => 'puppet:///modules/gdm/daemon.conf';

    '/etc/gdm3/greeter.dconf-defaults':
      require => [ File['/usr/share/backgrounds/puavo-art']
                 , Package['gdm3'] ],
      source  => 'puppet:///modules/gdm/greeter.dconf-defaults';
  }

  ::puavo_conf::script {
    'setup_xsessions':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/gdm/setup_xsessions';
  }

  Package <|
       title == gdm3
    or title == puavo-ltsp-client
  |>
}
