class extra_boot_scripts {
  include ::puavo_conf

  file {
    '/usr/local/sbin/puavo-run-extra-boot-scripts':
      mode   => '0755',
      source => 'puppet:///modules/extra_boot_scripts/puavo-run-extra-boot-scripts';
  }

  ::puavo_conf::definition {
    'puavo-admin-extra-boot-scripts.json':
      source => 'puppet:///modules/extra_boot_scripts/puavo-admin-extra-boot-scripts.json';
  }

  ::puavo_conf::script {
    'run_extra_boot_scripts':
      require => [ File['/usr/local/sbin/puavo-run-extra-boot-scripts']
                 , Puavo_conf::Definition['puavo-admin-extra-boot-scripts.json'] ],
      source  => 'puppet:///modules/extra_boot_scripts/run_extra_boot_scripts';
  }
}
