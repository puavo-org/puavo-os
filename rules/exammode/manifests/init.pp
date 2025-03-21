class exammode {
  include ::dconf::schemas
  include ::desktop::dconf::exammode
  include ::dpkg
  include ::gnome_shell_extensions::exammode
  include ::packages
  include ::puavo_conf
  include ::puavo_pkg::packages

  $puavo_exammode_dir     = '/var/lib/puavo-exammode'
  $puavo_examuser_homedir = "${puavo_exammode_dir}/user";
  $puavo_examuser_gid     = '989'
  $puavo_examuser_uid     = '989'

  ::dconf::schemas::schema {
    'org.gnome.desktop.lockdown.gschema.xml':
      require => Dpkg::Simpledivert['/usr/share/glib-2.0/schemas/org.gnome.desktop.lockdown.gschema.xml'],
      srcfile => 'puppet:///modules/exammode/org.gnome.desktop.lockdown.gschema.xml';
  }

  ::dpkg::simpledivert {
    '/usr/share/glib-2.0/schemas/org.gnome.desktop.lockdown.gschema.xml':
      require => Package['gsettings-desktop-schemas'];
  }

  file {
    '/etc/systemd/system/puavo-exammode-tty.service':
      require => Package['systemd'],
      source  => 'puppet:///modules/exammode/puavo-exammode-tty.service';

    '/etc/X11/Xsession.d/10puavo-set-exammode-session-quirks':
      source => 'puppet:///modules/exammode/10puavo-set-exammode-session-quirks';

    '/usr/local/bin/puavo-examusersh':
      mode   => '0755',
      source => 'puppet:///modules/exammode/puavo-examusersh';

    '/usr/local/lib/puavo-exammode':
      ensure => directory;

    '/usr/local/lib/puavo-exammode/exammode-gnome-session':
      mode   => '0755',
      source => 'puppet:///modules/exammode/exammode-gnome-session';

    '/usr/local/lib/puavo-exammode/exammode-session':
      mode    => '0755',
      require => Puavo_pkg::Install['ubuntu-wallpapers-bullseye'],
      source  => 'puppet:///modules/exammode/exammode-session';

    # Disable VT switching from keyboard.
    # The examination mode requires this for security.
    # XXX Note that Wayland may need something like this as well?
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

  ::puavo_conf::definition {
    'puavo-exammode.json':
      source => 'puppet:///modules/exammode/puavo-exammode.json';
  }

  Package <|
       title == 'gsettings-desktop-schemas'
    or title == 'systemd'
    or title == 'tomoyo-tools'
    or title == 'xinit'
    or title == 'xserver-xorg-core'
  |>

  Puavo_pkg::Install <| title == 'ubuntu-wallpapers-bullseye' |>
}
