Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', }
File { owner => 'root', group => 'root', mode => '0644', }

case $::puavoruleset {
  'prepare', 'prepare-fasttrack': {
    include ::apt::default_repositories
    include ::systemd::sysusers         # early so that this has an effect
  }

  'allinone': { include ::image::allinone }
}
