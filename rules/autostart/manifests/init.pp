class autostart {
  include ::puavo_conf

  file {
    [ '/etc/xdg/autostart.disabled', '/etc/X11/Xsession.d.disabled' ]:
      ensure => directory;
  }

  ::puavo_conf::definition {
    'puavo-xdg-autostart.json':
      source => 'puppet:///modules/autostart/puavo-xdg-autostart.json';
  }

  ::puavo_conf::script {
    'setup_xdg_autostart':
      require => [ File['/etc/X11/Xsession.d.disabled']
                 , File['/etc/xdg/autostart.disabled']
                 , ::Puavo_conf::Definition['puavo-xdg-autostart.json'] ],
      source  => 'puppet:///modules/autostart/setup_xdg_autostart';
  }
}
