class progressive_web_applications {
  include ::chromium

  define install ($browser='', $url, $app_id) {
    $pwa_name = $title

    exec {
      "/usr/local/lib/puavo-setup-pwa ${pwa_name} ${url} ${app_id} ${browser}":
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
      mode    => '0755',
      require => Puavo_conf::Script['setup_chromium'],
      source  => 'puppet:///modules/progressive_web_applications/puavo-setup-pwa';

    '/usr/local/lib/puavo-setup-guestuser-pwas':
      mode   => '0755',
      source => 'puppet:///modules/progressive_web_applications/puavo-setup-guestuser-pwas';
  }

  exec {
    'setup guestuser PWAs':
      command => '/usr/local/lib/puavo-setup-guestuser-pwas',
      require => [ File['/usr/local/lib/puavo-setup-guestuser-pwas']
                 , File['/var/lib/puavo-guestsetup']
                 , Package['chromium']
                 , User['puavo-guestsetup'] ],
      onlyif  => '/usr/bin/test ! -e /var/lib/puavo-guestsetup/guest-profile.tar -o /var/lib/puavo-guestsetup/guest-profile.tar -ot /var/lib/puavo-pwa -o /var/lib/puavo-guestsetup/guest-profile.tar -ot /usr/bin/google-chrome-stable',
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
