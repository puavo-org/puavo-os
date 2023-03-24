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
  # XXX (only require in case it is set to be installed)
  exec {
    'setup guestuser PWAs':
      command => '/usr/local/lib/puavo-setup-guestuser-pwas',
      require => [ File['/usr/local/lib/puavo-setup-guestuser-pwas']
                 , Package['chromium']
                 , User['puavo-guestsetup'] ],
      user    => 'puavo-guestsetup';
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
