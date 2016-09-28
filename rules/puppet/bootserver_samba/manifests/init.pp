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
      notify  => [ Service['nmbd']
                 , Service['smbd']
                 , Service['winbind'] ],
      require => Package['samba'];
  }

  exec {
    'fetch cifs.keytab':
      command => "/usr/bin/smbpasswd -w '${puavo_ldap_password}' && /usr/sbin/kadmin.local -q 'ktadd -norandkey -k /etc/samba/cifs.keytab cifs/${puavo_hostname}.${puavo_domain}'",
      creates => '/etc/samba/cifs.keytab',
      notify  => [ Service['nmbd'], Service['smbd'] ];
  }

  package {
    [ 'samba'
    , 'winbind' ]:
      ensure => present;
  }

  service {
    [ 'nmbd'
    , 'smbd' ]:
      enable  => true,
      ensure  => running,
      require => Package['samba'];

    'winbind':
      enable  => true,
      ensure  => running,
      require => Package['winbind'];
  }
}
