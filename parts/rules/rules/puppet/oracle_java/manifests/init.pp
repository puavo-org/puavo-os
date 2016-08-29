class oracle_java {
  include oracle_java::no_revocation_check,
          packages
  require oracle_java::tools

  file {
    '/usr/share/doc/oracle-java/puppet-subscription-flag':
      require => Package['oracle-java'],
      source  => 'puppet:///modules/oracle_java/puppet-subscription-flag';
  }

  exec {
    '/opt/java/opinsys-add-cert':
      refreshonly => true,
      require     => Package['oracle-java'],
      subscribe   => [ File['/opt/java/opinsys.keystore'],
                       File['/opt/java/opinsys-add-cert'],
                       File['/opt/java/ruleset.xml'],
                       File['/usr/share/doc/oracle-java/puppet-subscription-flag'],
                       Package['oracle-java'] ];

    '/opt/java/opinsys-create-signed-ruleset':
      refreshonly => true,
      require     => Package['oracle-java'],
      subscribe   => [ Exec['/opt/java/opinsys-add-cert'],
                       File['/opt/java/opinsys-create-signed-ruleset'],
                       File['/opt/java/ruleset.xml'] ];
  }

  Package <| title == oracle-java |>
}
