class packages::partner {
  include packages

  # install all ubuntu packages listed in packages
  Package <| tag == partner |> {
    ensure  => present,
    require => [ Exec['apt update'],
                 File['/etc/apt/sources.list.d/partner.list'], ],
  }

  # XXX this belongs a different place ... perhaps "apt"-module?
  # XXX sources list might belong there as well
  # XXX also, puppet stages would be nice here
  exec {
    'apt update':
      command     => '/usr/bin/apt-get update',
      refreshonly => true;
  }

  file {
    '/etc/apt/sources.list.d/partner.list':
      content => template('packages/partner.list'),
      notify  => Exec['apt update'];
  }
}
