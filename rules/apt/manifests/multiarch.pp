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

  if $architecture == 'amd64' {
    ::apt::multiarch::addarch { 'i386': ; }
  }
}
