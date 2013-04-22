class packages::opinsys {
  # XXX this class perhaps belongs elsewhere?

  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == liitu |>
  Apt::Repository <| title == taulu |>
}
