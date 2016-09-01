class bootserver_samba {

  $puavo_samba_domain = generate('/usr/bin/ruby1.9.3', '-e', '
require "puavo"
require "puavo/ldap"
print Puavo::Client::Base.new_by_ldap_entry(
  Puavo::Ldap.new.organisation).samba_domain_name
')

  file {
    '/etc/pam.d/samba':
      content => template('bootserver_samba/pam.samba'),
      mode    => 644;

    '/etc/samba/smb.conf':
      content => template('bootserver_samba/smb.conf'),
      mode    => 0644,
      notify  => [ Service['nmbd'], Service['smbd'] ],
      require => Package['samba'];
  }

  exec {
    '/usr/sbin/puavo-init-samba-server':
      creates => '/etc/samba/cifs.keytab';
  }

  package {
    'samba':
      ensure => present;
  }

  service {
    [ 'nmbd'
    , 'smbd' ]:
      enable  => true,
      ensure  => running,
      require => Package['samba'];
  }
}
