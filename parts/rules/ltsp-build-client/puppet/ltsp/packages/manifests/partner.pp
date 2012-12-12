class packages::partner {
  include packages

  # apply all package definitions with "partner"-tag listed in packages
  Package <| tag == partner |> {
    require => Apt::Repository['partner'],
  }

  Apt::Repository <| title == partner |>
}
