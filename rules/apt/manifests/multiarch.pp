class apt::multiarch {
  include ::apt

  define addarch () {
    $foreign_arch = $title

    exec {
      "/usr/bin/dpkg --add-architecture $foreign_arch":
        notify => Exec['apt update'],
        unless => "/usr/bin/dpkg --print-foreign-architectures | grep -qw $foreign_arch";
    }
  }

  if $deb_host_arch != 'i386' {
    ::apt::multiarch::addarch { 'i386': ; }
  }
}
