class packages::partner {
  include apt::repositories,
          packages

  # apply all package definitions with "partner"-tag listed in packages
  Package <| tag == partner |> {
    require => [ Apt::Repository['partner'], Exec['apt update'], ],
  }

  Apt::Repository <| title == partner |>
}
