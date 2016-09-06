class apt::multiarch {
  include apt

  define addarch () {
    $foreign_arch = $title

    exec {
      "/usr/bin/dpkg --add-architecture $foreign_arch":
        notify => Exec['apt update'],
        unless => "/usr/bin/dpkg --print-foreign-architectures | grep -qw $foreign_arch";
    }
  }

  case $lsbdistcodename {
    'precise': {}
    default: {
      case $architecture {
        'amd64': { addarch { 'i386':  ; } }
        'i386':  { addarch { 'amd64': ; } }
      }
    }
  }
}
