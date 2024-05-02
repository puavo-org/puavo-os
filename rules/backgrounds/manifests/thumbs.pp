class backgrounds::thumbs {
  require ::backgrounds
  include ::packages

  # The 'id' is used to ensure each directory is processed only once.
  # Remove the check file to re-process that directory.
  $src_dirs = [
    {
      'path' => '/usr/share/backgrounds',
      'id'   => 'backgrounds'
    },
    {
      'path' => '/usr/share/desktop-base',
      'id'   => 'desktop-base'
    }
  ]

  $dst_dir = '/usr/share/background-thumbnails'

  $src_dirs.each |$dir| {
    $stamp = "${dst_dir}/.${dir['id']}.thumbs_done"

    exec {
      "/usr/bin/makethumbs ${dir['path']} ${dst_dir} && /usr/bin/touch ${stamp}":
        creates   => $stamp,
        logoutput => 'on_failure',
        require   => [ File[$dst_dir]
                     , Package['puavo-devscripts'] ];
    }
  }

  file {
    $dst_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';

    '/etc/xdg/autostart/puavo-sync-wallpaper-thumbnails.desktop':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File['/usr/local/bin/puavo-sync-wallpaper-thumbnails'],
      source  => 'puppet:///modules/backgrounds/puavo-sync-wallpaper-thumbnails.desktop';

    '/usr/local/bin/puavo-sync-wallpaper-thumbnails':
      source => 'puppet:///modules/backgrounds/puavo-sync-wallpaper-thumbnails',
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
  }

  Package <| title == "puavo-devscripts" |>
}
