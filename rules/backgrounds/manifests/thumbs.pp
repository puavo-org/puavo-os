class backgrounds::thumbs {
  require ::backgrounds

  # The 'id' is used to ensure each directory is
  # processed only once. Remove the check file
  # to re-process that directory.
  $src_dirs =
  [
    {
      'path' => '/usr/share/backgrounds',
      'id'   => 'backgrounds'
    },
    {
      'path' => '/usr/share/desktop-base/futureprototype-theme/login',
      'id'   => 'desktop-base-futureprototype-login'
    },
    {
      'path' => '/usr/share/desktop-base/futureprototype-theme/wallpaper',
      'id'   => 'desktop-base-futureprototype-wallpaper'
    },
    {
      'path' => '/usr/share/desktop-base/futureprototype-theme/wallpaper-withlogo',
      'id'   => 'desktop-base-futureprototype-wallpaper-withlogo'
    },
    {
      'path' => '/usr/share/desktop-base/joy-theme/login',
      'id'   => 'desktop-base-joy-theme-login'
    },
    {
      'path' => '/usr/share/desktop-base/joy-theme/wallpaper',
      'id'   => 'desktop-base-joy-theme-wallpaper'
    },
    {
      'path' => '/usr/share/desktop-base/lines-theme/login',
      'id'   => 'desktop-base-lines-theme-login'
    },
    {
      'path' => '/usr/share/desktop-base/lines-theme/wallpaper',
      'id'   => 'desktop-base-lines-theme-wallpaper'
    },
    {
      'path' => '/usr/share/desktop-base/lines-theme/lockscreen',
      'id'   => 'desktop-base-lines-theme-lockscreen'
    },
    {
      'path' => '/usr/share/desktop-base/moonlight-theme/login',
      'id'   => 'desktop-base-moonlight-theme-login'
    },
    {
      'path' => '/usr/share/desktop-base/moonlight-theme/wallpaper',
      'id'   => 'desktop-base-moonlight-theme-wallpaper'
    },
    {
      'path' => '/usr/share/desktop-base/moonlight-theme/lockscreen',
      'id'   => 'desktop-base-moonlight-theme-lockscreen'
    },
    {
      'path' => '/usr/share/desktop-base/softwaves-theme/login',
      'id'   => 'desktop-base-softwaves-theme-login'
    },
    {
      'path' => '/usr/share/desktop-base/softwaves-theme/wallpaper',
      'id'   => 'desktop-base-softwaves-theme-wallpaper'
    },
    {
      'path' => '/usr/share/desktop-base/softwaves-theme/lockscreen',
      'id'   => 'desktop-base-softwaves-theme-lockscreen'
    },
    {
      'path' => '/usr/share/desktop-base/spacefun-theme/login',
      'id'   => 'desktop-base-spacefun-theme-login'
    }
  ]

  $dst_dir = "/usr/share/background-thumbnails"

  file {
    "$dst_dir":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
  }

  $src_dirs.each |$dir| {
    $stamp = "${dst_dir}/${dir['id']}"

    exec {
      "/usr/bin/makethumbs ${dir['path']} ${dst_dir} && touch ${stamp}":
        creates   => "${stamp}",
        logoutput => 'on_failure'
    }
  }

  file {
    '/usr/bin/puavo-sync-wallpaper-thumbnails':
      source => 'puppet:///modules/backgrounds/puavo-sync-wallpaper-thumbnails',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
  }

  file {
    '/etc/xdg/autostart/puavo-sync-wallpaper-thumbnails.desktop':
      source => 'puppet:///modules/backgrounds/puavo-sync-wallpaper-thumbnails.desktop',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
  }
}
