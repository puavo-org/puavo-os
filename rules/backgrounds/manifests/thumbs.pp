class backgrounds::thumbs {
  require ::backgrounds

  # The 'id' is used to ensure each directory is
  # processed only once. Remove the check file
  # to re-process that directory.
  $src_dirs =
  [
    {
      'path' => '/usr/share/backgrounds',
      'id'   => 'backgrounds'
    },
    {
      'path' => '/usr/share/desktop-base',
      'id'   => 'desktop-base'
    }
  ]

  $dst_dir = "/usr/share/background-thumbnails"

  file {
    "$dst_dir":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
  }

  $src_dirs.each |$dir| {
    $stamp = "${dst_dir}/${dir['id']}"

    exec {
      "/usr/bin/makethumbs ${dir['path']} ${dst_dir} && touch ${stamp}":
        creates   => "${stamp}",
        logoutput => 'on_failure'
    }
  }
}
