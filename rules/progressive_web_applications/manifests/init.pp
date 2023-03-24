class progressive_web_applications {
  define install ($browser='', $url) {
    $pwa_name = $title

    exec {
      "/usr/local/lib/puavo-setup-pwa ${pwa_name} ${url} ${browser}":
        creates => "/var/lib/puavo-pwa/${pwa_name}",
        before  => Exec['setup guestuser PWAs'],
        require => File['/usr/local/lib/puavo-setup-pwa'];
    }
  }

  file {
    '/etc/X11/Xsession.d/80puavo-setup-pwas':
      source => 'puppet:///modules/progressive_web_applications/80puavo-setup-pwas';

    '/usr/local/bin/puavo-pwa':
      mode   => '0755',
      source => 'puppet:///modules/progressive_web_applications/puavo-pwa';

    '/usr/local/lib/puavo-setup-pwa':
      mode   => '0755',
      source => 'puppet:///modules/progressive_web_applications/puavo-setup-pwa';

    '/usr/local/lib/puavo-setup-guestuser-pwas':
      mode   => '0755',
      source => 'puppet:///modules/progressive_web_applications/puavo-setup-guestuser-pwas';
  }

  # XXX this should actually setup stuff for both chrome and chromium?
  # XXX (in case chrome is installed into the system)
  # XXX Puavo_pkg::Install['google-chrome'] should be conditionally required
  # XXX (only require it in case it is set to be installed)
  exec {
    'setup guestuser PWAs':
      command => '/usr/local/lib/puavo-setup-guestuser-pwas',
      require => [ File['/usr/local/lib/puavo-setup-guestuser-pwas']
                 , File['/var/lib/puavo-guestsetup']
                 , Package['chromium']
                 , User['puavo-guestsetup'] ],
      user    => 'puavo-guestsetup';
  }

  file {
    '/var/lib/puavo-guestsetup':
      ensure => directory,
      owner  => 'puavo-guestsetup',
      group  => 'puavo-guestsetup';
  }

  user {
    'puavo-guestsetup':
      ensure     => present,
      comment    => 'Puavo Guest User Setup',
      home       => '/var/lib/puavo-guestsetup/home',
      managehome => true,
      shell      => '/bin/false',
      system     => true,
      uid        => 990;
  }
}
