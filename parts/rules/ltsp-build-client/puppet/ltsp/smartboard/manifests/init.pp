class smartboard {
  include packages,
          smartboard::config,
          smartboard::notebook_cache_wrapper,
          smartboard::startup

  # smart-product-drivers does not install on our image build process,
  # unless it thinks we are Linkat or Suse.  We choose to mask ourselves as
  # Linkat (Ubuntu based distribution used in Spain, see
  # http://linkat.xtec.cat/portal/index.php).
  file {
    '/etc/Linkat':
      before => Package['smart-product-drivers'],
      ensure => present;
  }

  Package <| tag == whiteboard-smartboard |>
}
