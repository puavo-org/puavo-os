class packages::partner {
  include packages

  Apt::Repository <| title == partner |>
}
