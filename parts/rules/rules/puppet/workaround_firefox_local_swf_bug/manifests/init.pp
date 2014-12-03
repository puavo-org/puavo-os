class workaround_firefox_local_swf_bug {
  include dpkg,
          packages

  $mimexml_file = '/usr/share/mime/packages/freedesktop.org.xml'

  dpkg::simpledivert { $mimexml_file: ; }

  exec {
    'update-mime-database':
      command     => '/usr/bin/update-mime-database /usr/share/mime',
      refreshonly => true;
  }

  file {
    $mimexml_file:
      notify  => Exec['update-mime-database'],
      require => [ Dpkg::Simpledivert[$mimexml_file]
                 , Package['shared-mime-info'] ],
      source => 'puppet:///modules/workaround_firefox_local_swf_bug/freedesktop.org.xml';
  }

  Package <| title == shared-mime-info |>
}
