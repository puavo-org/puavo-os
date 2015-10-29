class image::thinclient {
  include image::bundle::basic,
          packages,
          xorg_driver_switches

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == proposed
                  or title == repo
                  or title == xorg-updates |>

  # apply only thinclient package definitions listed in packages
  Package <| tag == thinclient |>
}
