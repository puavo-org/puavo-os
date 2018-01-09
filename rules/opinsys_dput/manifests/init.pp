class opinsys_dput {
  include ::packages

  # Configuration for uploading Debian packages to archive.opinsys.fi.

  file {
    '/etc/dput.cf':
      require => Package['dput'],
      source  => 'puppet:///modules/dput/dput.cf';
  }

  Package <| title == dput |>
}
