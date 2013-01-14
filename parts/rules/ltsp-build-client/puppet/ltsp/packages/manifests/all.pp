class packages::all {
  include packages,
          packages::opinsys,
          packages::partner

  # apply all package definitions listed in packages
  Package <| |>
}
