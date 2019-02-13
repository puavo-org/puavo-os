class google_cloud_print {
  include packages
  include puavo_conf

  file {
    '/etc/systemd/system/multi-user.target.wants/google-cloud-print.service':
      ensure  => link,
      require => File['/etc/systemd/system/google-cloud-print.service'],
      target  => '/etc/systemd/system/google-cloud-print.service';

    '/etc/systemd/system/google-cloud-print.service':
      require => [ Package['google-cloud-print-connector'],
                   User['gcp'], ],
      source  => 'puppet:///modules/google_cloud_print/google-cloud-print.service';

  }

  ::puavo_conf::definition {
    'puavo-google-cloud-print.json':
      source => 'puppet://modules/google_cloud_print/puavo-google-cloud-print.json';
  }

  user {
    'gcp':
      ensure     => present,
      comment    => 'Google Cloud Print Connector',
      home       => '/var/lib/gcp',
      managehome => true,
      shell      => '/bin/false',
      system     => true,
      uid        => 990;
  }

  Package <| title == 'google-cloud-print-connector' |>
}
