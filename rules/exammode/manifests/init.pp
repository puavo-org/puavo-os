class exammode {
  # Disable VT switching from keyboard.
  # The examination mode requires this for security.
  # XXX Note that Wayland may need something like this as well?

  $puavo_examuser_homedir = '/var/lib/puavo-exammode/user'
  $puavo_examuser_gid     = '989'
  $puavo_examuser_uid     = '989'

  file {
    '/etc/dbus-1/system.d/org.puavo.Exam.conf':
      source => 'puppet:///modules/exammode/org.puavo.Exam.conf';

    '/etc/systemd/system/gdm3.service.d':
      ensure => directory;

    '/etc/systemd/system/gdm3.service.d/override.conf':
      source => 'puppet:///modules/exammode/gdm3_service_override.conf';

    '/etc/systemd/system/multi-user.target.wants/puavo-exammode-tty.service':
      ensure  => link,
      require => File['/etc/systemd/system/puavo-exammode-tty.service'],
      target  => '/etc/systemd/system/puavo-exammode-tty.service';

    '/etc/systemd/system/puavo-exammode-tty.service':
      require => Package['systemd'],
      source  => 'puppet:///modules/exammode/puavo-exammode-tty.service';

    '/etc/X11/Xsession.d/10puavo-set-exammode-session-quirks':
      source => 'puppet:///modules/exammode/10puavo-set-exammode-session-quirks';

    '/usr/lib/puavo-ltsp-client/exammode-session':
      mode   => '0755',
      source => 'puppet:///modules/exammode/exammode-session';

    '/usr/local/bin/puavo-examusersh':
      mode   => '0755',
      source => 'puppet:///modules/exammode/puavo-examusersh';

    '/usr/local/sbin/puavo-exammode-manager':
      mode   => '0755',
      source => 'puppet:///modules/exammode/puavo-exammode-manager';

    '/usr/share/dbus-1/system-services/org.puavo.Exam.service':
      source => 'puppet:///modules/exammode/org.puavo.Exam.service';

    '/usr/share/X11/xorg.conf.d/90-disable-vtswitch.conf':
      require => Package['xserver-xorg-core'],
      source  => 'puppet:///modules/exammode/90-disable-vtswitch.conf';

    '/var/lib/puavo-exammode':
      ensure => directory;

    # intentionally owned by root:root
    $puavo_examuser_homedir:
      ensure => directory,
      mode   => '0700';
  }

  group {
    'puavo-examuser':
      ensure => present,
      gid    => $puavo_examuser_gid,
      system => true;
  }

  user {
    'puavo-examuser':
      ensure     => present,
      comment    => 'Puavo Exam User',
      gid        => $puavo_examuser_gid,
      home       => $puavo_examuser_homedir,
      require    => [ File['/usr/local/bin/puavo-examusersh']
                    , Group['puavo-examuser'], ],
      shell      => '/usr/local/bin/puavo-examusersh',
      system     => true,
      uid        => $puavo_examuser_uid;
  }

  Package <|
       title == 'systemd'
    or title == 'tomoyo-tools'
    or title == 'xserver-xorg-core'
  |>
}
