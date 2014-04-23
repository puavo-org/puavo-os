class plymouth_theme {
  include packages,
          plymouth_theme::initramfs

  $plymouth_theme_script = '/lib/plymouth/themes/opinmouth/opinmouth.plymouth'
  $plymouth_theme_text   = '/lib/plymouth/themes/opinmouth-text/opinmouth-text.plymouth'

  exec {
    'set plymouth default theme':
      command => "/usr/bin/update-alternatives --set default.plymouth '$plymouth_theme_script'",
      notify  => Exec['update-initramfs'],
      require => Package['opinsys-theme'],
      unless  => "/usr/bin/update-alternatives --query default.plymouth | /bin/fgrep -qx 'Status: manual'";
  }

  exec {
    'set plymouth text theme':
      command => "/usr/bin/update-alternatives --set text.plymouth '$plymouth_theme_text'",
      notify  => Exec['update-initramfs'],
      require => Package['opinsys-theme'],
      unless  => "/usr/bin/update-alternatives --query text.plymouth | /bin/fgrep -qx 'Status: manual'";
  }

  # this package contains $plymouth_theme_script
  Package <| title == 'opinsys-theme' |>
}
