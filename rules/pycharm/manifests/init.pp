class pycharm {
  include packages

  file {
    '/opt/pycharm/opinsys-default-options':
      recurse => true,
      require => Package['pycharm'],
      source  => 'puppet:///modules/pycharm/opinsys-default-options';
  }

  file {
    '/opt/pycharm/bin/pycharm-wrapper':
      mode    => '0755',
      require => File['/opt/pycharm/opinsys-default-options'],
      source  => 'puppet:///modules/pycharm/pycharm-wrapper';
  }

  file {
    '/usr/share/applications/pycharm.desktop':
      require => File['/opt/pycharm/bin/pycharm-wrapper'],
      source  => 'puppet:///modules/pycharm/pycharm.desktop';
  }

  Package <| title == pycharm |>
}
