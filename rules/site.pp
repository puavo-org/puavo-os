Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', }
File { owner => 'root', group => 'root', mode => '0644', }

case $::puavoruleset {
  'prepare': {
    include ::apt::default_repositories
    include ::ca_certificate_workarounds
  }
  'allinone': { include ::image::allinone }
}
