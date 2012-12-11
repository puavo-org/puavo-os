class packages::all {
  include packages,
          packages::partner,
          packages::ubuntu

  # apply all package definitions listed in packages
  Package <| |>
}
