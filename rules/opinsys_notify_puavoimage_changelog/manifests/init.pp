class opinsys_notify_puavoimage_changelog {
  include opinsyspackages

  $nw_dir = '/usr/local/share/notify_puavoimage_changelog/node-webkit-app'

  file {
    '/etc/xdg/autostart/notify_puavoimage_changelog.desktop':
      require => File['/usr/local/bin/notify_puavoimage_changelog'],
      source  => 'puppet:///modules/opinsys_notify_puavoimage_changelog/notify_puavoimage_changelog.desktop';

    '/usr/local/bin/notify_puavoimage_changelog':
      mode    => 755,
      require => [ File["${nw_dir}/package.json"]
                 , Package['python-appindicator']
                 , Package['python-gtk2']
                 , Package['python-notify'] ],
      source  => 'puppet:///modules/opinsys_notify_puavoimage_changelog/notify_puavoimage_changelog';

    [ '/usr/local/share/notify_puavoimage_changelog', $nw_dir, ]:
      ensure => directory;

    "${nw_dir}/index.html":
      require => File["${nw_dir}/index.js"],
      source  => 'puppet:///modules/opinsys_notify_puavoimage_changelog/node-webkit-app/index.html';

    "${nw_dir}/index.js":
      source => 'puppet:///modules/opinsys_notify_puavoimage_changelog/node-webkit-app/index.js';

    "${nw_dir}/package.json":
      require => [ File["${nw_dir}/index.html"], Package['node-webkit'] ],
      source  => 'puppet:///modules/opinsys_notify_puavoimage_changelog/node-webkit-app/package.json';
  }

  Package <| title == node-webkit
          or title == python-appindicator
          or title == python-gtk2
          or title == python-notify |>
}
