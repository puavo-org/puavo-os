class devilspie {
  include ::packages
  include ::puavo_conf

  file {
    [ '/etc/devilspie2', '/etc/xdg/autostart' ]:
      ensure => directory;

    '/etc/devilspie2/maximize_windows.lua.off':
      source => 'puppet:///modules/devilspie/scripts/maximize_windows.lua';

    '/etc/xdg/autostart/devilspie2.desktop':
      source => 'puppet:///modules/devilspie/devilspie2.desktop';
  }

  ::puavo_conf::definition {
    'puavo-devilspie.json':
      source => 'puppet:///modules/devilspie/puavo-devilspie.json';
  }

  ::puavo_conf::script {
    'setup_devilspie':
      source => 'puppet:///modules/devilspie/setup_devilspie';
  }

  Package <| title == devilspie2 |>
}
