class kernels::dkms {
  # Install dkms module packages before any kernels, that way we should get
  # them for all packages.

  $dkms_module_packages = $lsbdistcodename ? {
                            'precise' => [],
                            default   => [ 'bcmwl-kernel-source', 'nvidia-304', ],
                          }

  Package <| tag == kernel |> {
    require +> Package[ $dkms_module_packages ],
  }
}
