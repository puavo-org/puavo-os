class kernels::dkms {
  include packages

  # Install dkms module packages before any kernels, that way we should get
  # them for all packages.

  $dkms_module_packages =
    $lsbdistcodename ? {
      'precise' => [],
      default   => [ 'bcmwl-kernel-source', 'nvidia-304', 'r8168-dkms', ],
    }

  Package <| tag == kernel |> {
    require +> Package[$dkms_module_packages],
  }

  realize(Package[$dkms_module_packages])
}
