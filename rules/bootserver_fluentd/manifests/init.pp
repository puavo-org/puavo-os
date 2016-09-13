class bootserver_fluentd {

  file {
    '/etc/fluent/conf.d/01-puavo.conf':
      notify  => Service['fluentd'],
      source => 'puppet:///modules/bootserver_fluentd/01-puavo.conf';

    '/etc/fluent/conf.d/puavo.conf':
      notify  => Service['fluentd'],
      source => 'puppet:///modules/bootserver_fluentd/puavo.conf';

    '/usr/local/bin/puavo-bootserver-autopilot-cat':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_fluentd/puavo-bootserver-autopilot-cat';

    '/usr/local/bin/puavo-bootserver-smoke-test-cat':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_fluentd/puavo-bootserver-smoke-test-cat';
  }

  service {
    'fluentd':
      enable  => 'true',
      ensure  => 'running';
  }

}
