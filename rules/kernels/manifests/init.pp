class kernels {
  include ::kernels::dkms
  include ::kernels::grub_update
  include ::packages

  $kernel_versions = {
    'default' => '6.1.0-31-amd64',
    'crisp'   => '6.12.9+bpo-amd64',
  }
  $kernel_aliases = keys($kernel_versions)

  define kernel_link ($kernel_alias, $linkname, $linksuffix, $version) {
    file {
      "/boot/${linkname}${linksuffix}":
        ensure  => link,
        require => Packages::Kernels::Kernel_package[$kernel_alias],
        target  => "${linkname}-${version}";
    }

    Packages::Kernels::Kernel_package <| title == $kernel_alias |>
  }

  define all_kernel_links ($kernel_alias, $version) {
    $subname = $title

    $linksuffix = $subname ? { 'default' => '', default => "-$subname", }

    ::kernels::kernel_link {
      "initrd.img-${version}-${subname}":
        kernel_alias => $kernel_alias,
        linkname     => 'initrd.img',
        linksuffix   => $linksuffix,
        version      => $version;

      "vmlinuz-${version}-${subname}":
        kernel_alias => $kernel_alias,
        linkname     => 'vmlinuz',
        linksuffix   => $linksuffix,
        version      => $version;
    }
  }

  define install_kernel {
    $kernel_alias = $title

    ::kernels::all_kernel_links {
      $kernel_alias:
        kernel_alias => $kernel_alias,
        require      => Packages::Kernels::Kernel_package[$kernel_alias],
        version      => $::kernels::kernel_versions[$kernel_alias];
    }

    Packages::Kernels::Kernel_package <| title == $kernel_alias |>
  }

  @::kernels::install_kernel { $kernel_aliases: ; }
}
