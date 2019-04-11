class nightly_updates {
  include ::puavo_conf

  file {
    '/usr/local/lib/puavo-nightly-updates':
      mode    => '0755',
      require => ::Puavo_conf::Definition['puavo-admin-nightly-updates.json'],
      source  => 'puppet:///modules/nightly_updates/puavo-nightly-updates';
  }

  ::puavo_conf::definition {
    'puavo-admin-nightly-updates.json':
      source => 'puppet:///modules/nightly_updates/puavo-admin-nightly-updates.json';
  }
}
