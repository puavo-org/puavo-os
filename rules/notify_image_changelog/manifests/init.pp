class notify_image_changelog {
  include ::packages

  $nw_dir = '/usr/local/share/notify_puavoimage_changelog/nwjs-app'

  file {
    '/etc/xdg/autostart/notify_puavoimage_changelog.desktop':
      require => File['/usr/local/bin/notify_puavoimage_changelog'],
      source  => 'puppet:///modules/notify_image_changelog/notify_puavoimage_changelog.desktop';

    '/usr/local/bin/notify_puavoimage_changelog':
      mode    => '0755',
      require => [ File["${nw_dir}/package.json"]
                 , Package['faenza-icon-theme']
                 , Package['python-appindicator']
                 , Package['python-gtk2']
                 , Package['python-notify'] ],
      source  => 'puppet:///modules/notify_image_changelog/notify_puavoimage_changelog';

    [ '/usr/local/share/notify_puavoimage_changelog', $nw_dir, ]:
      ensure => directory;

    "${nw_dir}/index.html":
      require => File["${nw_dir}/index.js"],
      source  => 'puppet:///modules/notify_image_changelog/nwjs-app/index.html';

    "${nw_dir}/index.js":
      source => 'puppet:///modules/notify_image_changelog/nwjs-app/index.js';

    "${nw_dir}/package.json":
      require => [ File["${nw_dir}/index.html"], Package['nwjs'] ],
      source  => 'puppet:///modules/notify_image_changelog/nwjs-app/package.json';
  }

  Package <| title == faenza-icon-theme
          or title == nwjs
          or title == python-appindicator
          or title == python-gtk2
          or title == python-notify |>
}
