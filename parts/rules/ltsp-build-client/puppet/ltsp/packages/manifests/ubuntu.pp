class packages::ubuntu {
  include packages

  Package <| tag == ubuntu |>
}
