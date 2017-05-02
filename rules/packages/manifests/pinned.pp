class packages::pinned {
  define pin_package ($version, $taglist) {
    $package = $title

    @package {
      $package:
	ensure  => $version,
	require => Apt::Pin[$package],
	tag     => $taglist;
    }

    ::apt::pin {
      $package:
	version => $version;
    }
  }
}
