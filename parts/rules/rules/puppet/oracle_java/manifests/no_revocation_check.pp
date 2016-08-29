class oracle_java::no_revocation_check {
  # Disable revocation check for Java (for Ekapeli, but has an effect on
  # others as well).  This was not needed for Oracle Java 1.7.71, but seems
  # preferable for 1.7.75 to avoid a warning.  It is unclear if the revocation
  # check actually worked in 1.7.71 either, this is because when setting
  # "Perform certificate revocation checks on All certificates in the chain of
  # trust" with jcontrol in 1.7.71, the actual setting in
  # ~/.java/deployment/config.cache will be
  # "deployment.security.tls.revocation.check=NO_CHECK".

  file {
    [ '/etc/.java', '/etc/.java/deployment' ]:
      ensure => directory;

    '/etc/.java/deployment/deployment.config':
      source => 'puppet:///modules/oracle_java/deployment.config';

    '/etc/.java/deployment/deployment.properties':
      source => 'puppet:///modules/oracle_java/deployment.properties';
  }
}
