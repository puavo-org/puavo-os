class packages::thinclient {
  include packages,
          packages::opinsys

  # apply only thinclient package definitions listed in packages
  Package <| tag == thinclient |>
}
