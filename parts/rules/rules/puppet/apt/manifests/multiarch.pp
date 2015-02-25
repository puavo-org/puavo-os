class apt::multiarch {
  include apt

  if $architecture == 'amd64' {
    exec {
      '/usr/bin/dpkg --add-architecture i386':
        notify => Exec['apt update'],
        unless => '/usr/bin/dpkg --print-foreign-architectures | grep -qw i386';
    }
  }
}
