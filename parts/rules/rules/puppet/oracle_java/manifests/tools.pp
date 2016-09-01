class oracle_java::tools {
  include packages

  file {
    '/etc/puavo-external-files-actions.d/java':
      mode    => 755,
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/oracle_java/puavo-external-files-actions.d/java';

    '/opt/java':
      ensure => directory;

    '/opt/java/opinsys-add-cert':
      mode   => 0700,
      source => 'puppet:///modules/oracle_java/opinsys-add-cert';

    '/opt/java/opinsys-create-signed-ruleset':
      mode   => 0700,
      source => 'puppet:///modules/oracle_java/opinsys-create-signed-ruleset';

    '/opt/java/opinsys.keystore':
      mode   => 0600,
      source => 'puppet:///modules/oracle_java/opinsys.keystore';

    '/opt/java/ruleset.xml':
      source => 'puppet:///modules/oracle_java/ruleset.xml';
  }

  Package <| title == puavo-ltsp-client |>
}
