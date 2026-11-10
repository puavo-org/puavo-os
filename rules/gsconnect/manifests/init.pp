class gsconnect {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/X11/Xsession.d/46puavo-setup-gsconnect':
      require => Package['x11-common'],
      source  => 'puppet:///modules/gsconnect/46puavo-setup-gsconnect';
  }

  ::puavo_conf::definition {
    'puavo-gsconnect.json':
      source => 'puppet:///modules/gsconnect/puavo-gsconnect.json';
  }

  Package <| title == 'x11-common' |>
}
