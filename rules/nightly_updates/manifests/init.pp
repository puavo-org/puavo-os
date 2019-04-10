class nightly_updates {
  include ::puavo_conf

  file {
    '/usr/local/lib/puavo-trigger-nightly-updates':
      mode    => '0755',
      require => ::Puavo_conf::Definition['puavo-admin-nightly-updates'],
      source  => 'puppet:///modules/nightly_updates/puavo-trigger-nightly-updates';
  }

  ::puavo_conf::definition {
    'puavo-admin-nightly-updates.json':
      source => 'puppet:///modules/nightly_updates/puavo-admin-nightly-updates.json';
  }
}
