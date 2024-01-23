class exammode {
  # Disable VT switching from keyboard.
  # The examination mode requires this for security.
  # XXX Note that Wayland may need something like this as well?

  file {
    '/etc/dbus-1/system.d/org.puavo.Exam.conf':
      source => 'puppet:///modules/exammode/org.puavo.Exam.conf';

    '/usr/local/bin/puavo-switch-to-exammode':
      mode   => '0755',
      source => 'puppet:///modules/exammode/puavo-switch-to-exammode';

    '/usr/local/sbin/puavo-exammode-manager':
      mode   => '0755',
      source => 'puppet:///modules/exammode/puavo-exammode-manager';

    '/usr/share/dbus-1/system-services/org.puavo.Exam.service':
      source => 'puppet:///modules/exammode/org.puavo.Exam.service';

    '/usr/share/X11/xorg.conf.d/90-disable-vtswitch.conf':
      require => Package['xserver-xorg-core'],
      source  => 'puppet:///modules/exammode/90-disable-vtswitch.conf';
  }

  Package <| title == 'xserver-xorg-core' |>
}
