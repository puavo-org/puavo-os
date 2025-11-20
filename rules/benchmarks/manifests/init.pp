class benchmarks {
  include ::packages
  include ::puavo_pkg::packages

  file {
    '/usr/local/sbin/puavo-benchmark':
      mode    => '0755',
      require => [ Package['yq']
                 , Puavo_pkg::Install['passmark-performance-test'] ],
      source  => 'puppet:///modules/benchmarks/puavo-benchmark';

    '/var/lib/puavo/benchmark':
      ensure => directory;
  }

  # puavo-core should setup /var/lib/puavo
  Package <|
       title == puavo-core
    or title == yq
  |>

  Puavo_pkg::Install <| title == passmark-performance-test |>
}
