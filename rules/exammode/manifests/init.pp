class exammode {
  # Disable VT switching from keyboard.
  # The examination mode requires this for security.
  # XXX Note that Wayland may need something like this as well?

  file {
    '/usr/share/X11/xorg.conf.d/90-disable-vtswitch.conf':
      require => Package['xserver-xorg-core'],
      source  => 'puppet:///modules/exammode/90-disable-vtswitch.conf';
  }

  Package <| title == 'xserver-xorg-core' |>
}
