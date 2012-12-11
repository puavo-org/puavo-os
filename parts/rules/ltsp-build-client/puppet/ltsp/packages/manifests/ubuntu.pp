class packages::ubuntu {
  include packages

  # apply all package definitions with "ubuntu"-tag listed in packages
  Package <| tag == ubuntu |>
}
