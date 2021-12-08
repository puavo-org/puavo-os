class bootserver_hooktftp {
  include ::packages

  file {
    '/etc/hooktftp.yml':
       require => Package['hooktftp'],
       source  => 'puppet:///modules/bootserver_hooktftp/hooktftp.yml';

    '/usr/local/sbin/puavo-ltspboot-config':
       mode => '0755',
       source  => 'puppet:///modules/bootserver_hooktftp/puavo-ltspboot-config';
  }

  Package <| title == hooktftp |>
}
