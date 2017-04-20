class guest {
  file {
    '/etc/guest-session':
      ensure => directory;

    '/etc/guest-session/reset-guestuser-home':
      mode   => '0755',
      source => 'puppet:///modules/guest/guest-session/reset-guestuser-home';

    '/etc/guest-session/skel':
      recurse => true,
      source  => 'puppet:///modules/guest/guest-session/skel';
  }
}
