Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', }
File { owner => 'root', group => 'root', mode => '0644', }

case $::puavoruleset {
  'prepare': {
    require ::apt::default_repositories
    include ::systemd::sysusers         # early so that this has an effect
    include ::users                     # early so that this has an effect

    case $::puavoimage_class {
      'exam': {
        include ::apt::no_install_recommends
      }
    }

    # workaround Java installation bug that looked like
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1042732
    package {
      'ca-certificates-java':
        ensure => present;
    }
  }

  'allinone': { include ::image::allinone }
  'exam':     { include ::image::exam     }
}
