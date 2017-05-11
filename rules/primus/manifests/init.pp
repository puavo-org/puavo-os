class primus {
  include ::puavo_external_files

  file {
    '/etc/puavo-external-files-actions.d/primus':
      content => template('primus/puavo-external-files-actions.d/primus'),
      mode    => '0755';

    '/opt/primus':
      ensure => directory;

    '/opt/primus/primusclient.desktop':
      content => template('primus/primusclient.desktop'),
      require => [ File['/opt/primus/starsoft.png']
                 , File['/usr/local/bin/primusclient'] ];

    '/opt/primus/starsoft.png':
      source => 'puppet:///modules/primus/starsoft.png';

    '/usr/local/bin/primusclient':
      content => template('primus/primusclient'),
      mode    => '0755';
  }

  ::puavo_external_files::external_file {
    '/opt/primus/prclient.ini':
      external_file_name => 'prclient.ini';

    '/opt/primus/primuskurre.exe':
      external_file_name => 'primuskurre.exe';
  }
}
