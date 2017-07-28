class notify_changelog {
  include ::packages

  $nw_dir = '/usr/local/share/puavo-notify-changelog/nwjs-app'

  file {
    '/etc/xdg/autostart/puavo-notify-changelog.desktop':
      require => File['/usr/local/bin/puavo-notify-changelog'],
      source  => 'puppet:///modules/notify_changelog/puavo-notify-changelog.desktop';

    '/usr/local/bin/puavo-notify-changelog':
      mode    => '0755',
      require => [ File["${nw_dir}/package.json"]
                 , Package['faenza-icon-theme']
                 , Package['python-appindicator']
                 , Package['python-gtk2']
                 , Package['python-notify'] ],
      source  => 'puppet:///modules/notify_changelog/puavo-notify-changelog';

    [ '/usr/local/share/puavo-notify-changelog', $nw_dir, ]:
      ensure => directory;

    "${nw_dir}/index.html":
      require => File["${nw_dir}/index.js"],
      source  => 'puppet:///modules/notify_changelog/nwjs-app/index.html';

    "${nw_dir}/index.js":
      source => 'puppet:///modules/notify_changelog/nwjs-app/index.js';

    "${nw_dir}/package.json":
      require => [ File["${nw_dir}/index.html"], Package['nwjs'] ],
      source  => 'puppet:///modules/notify_changelog/nwjs-app/package.json';
  }

  Package <| title == faenza-icon-theme
          or title == nwjs
          or title == python-appindicator
          or title == python-gtk2
          or title == python-notify |>
}
