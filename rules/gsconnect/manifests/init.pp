class gsconnect {
  include ::gsconnect::dconf
  include ::packages
  include ::puavo_conf

  file {
    '/etc/X11/Xsession.d/46puavo-setup-gsconnect':
      require => [ File['/usr/local/bin/puavo-gsconnect']
                 , Package['x11-common'] ],
      source  => 'puppet:///modules/gsconnect/46puavo-setup-gsconnect';

    '/usr/local/bin/puavo-gsconnect':
      mode   => '0755',
      source => 'puppet:///modules/gsconnect/puavo-gsconnect';

    '/usr/local/share/applications/puavo-gsconnect.desktop':
      require => File['/usr/local/bin/puavo-gsconnect'],
      source  => 'puppet:///modules/gsconnect/puavo-gsconnect.desktop';
  }

  ::puavo_conf::definition {
    'puavo-gsconnect.json':
      source => 'puppet:///modules/gsconnect/puavo-gsconnect.json';
  }

  Package <| title == 'x11-common' |>
}
