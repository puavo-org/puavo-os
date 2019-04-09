class nightly_updates {
  include ::puavo_conf

  file {
    '/lib/systemd/system-sleep/puavo-updates-on-resume':
      mode   => '0755',
      source => 'puppet:///modules/nightly_updates/lib_systemd_system-sleep_puavo-updates-on-resume';

    '/usr/local/lib/puavo-trigger-nightly-updates':
      mode   => '0755',
      source => 'puppet:///modules/nightly_updates/puavo-trigger-nightly-updates';

    '/usr/local/lib/puavo-updates-on-resume':
      mode   => '0755',
      source => 'puppet:///modules/nightly_updates/puavo-updates-on-resume';
  }

  ::puavo_conf::definition {
    'puavo-admin-nightly-updates':
      source => 'puppet:///modules/nightly_updates/puavo-admin-nightly-updates.json';
  }
}
