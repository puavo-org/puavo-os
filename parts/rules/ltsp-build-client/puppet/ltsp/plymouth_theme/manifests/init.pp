class plymouth_theme {
  include packages,
          plymouth_theme::initramfs

  $plymouth_theme_script = '/lib/plymouth/themes/opinmouth/opinmouth.plymouth'

  exec {
    'set plymouth default theme':
      command => "/usr/bin/update-alternatives --set default.plymouth '$plymouth_theme_script'",
      notify  => Exec['update-initramfs'],
      require => Package['liitu-themes'],
      unless  => "/usr/bin/test \"\$(/bin/readlink /etc/alternatives/default.plymouth)\" = '$plymouth_theme_script'";
  }

  # this package contains $plymouth_theme_script
  Package <| title == 'liitu-themes' |>
}
