class ncurses {
  include ::packages

  # PassMark CPU Benchmark needs libncurses5 (at least in version
  # v11.0 Build 1004, November 12 2025).  It is missing from Trixie,
  # but we lie that libncurses6 is good, and the test appears to run.

  file {
    '/usr/lib/x86_64-linux-gnu/libncurses.so.5':
      ensure  => link,
      require => Package['libncurses6'],
      target  => 'libncurses.so.6.5';
  }

  Package <| title == libncurses6 |>
}
