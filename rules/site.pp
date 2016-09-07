Exec { path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', }
File { owner => 'root', group => 'root', mode => 644, }

case $::puavoruleset {
  'prepare':  { include ::apt::default_repositories }
  'allinone': { include ::image::allinone           }
}
