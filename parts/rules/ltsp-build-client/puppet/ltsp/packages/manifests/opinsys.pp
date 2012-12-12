class packages::opinsys {
  include apt::repositories,
          packages

  # apply all package definitions with "opinsys"-tag listed in packages
  Package <| tag == opinsys |> {
    require => [ Apt::Repository['liitu'], Exec['apt update'], ],
  }

  Apt::Repository <| title == liitu |>
}
