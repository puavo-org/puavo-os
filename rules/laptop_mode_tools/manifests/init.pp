class laptop_mode_tools {
  include ::dpkg
  include ::packages

  dpkg::simpledivert {
    '/etc/laptop-mode/conf.d/usb-autosuspend.conf':
      before => File['/etc/laptop-mode/conf.d/usb-autosuspend.conf'];
  }

  file {
    '/etc/laptop-mode/conf.d/usb-autosuspend.conf':
      require => Package['laptop-mode-tools'],
      source  => 'puppet:///modules/laptop_mode_tools/usb-autosuspend.conf';
  }

  Package <| title == laptop-mode-tools |>
}
