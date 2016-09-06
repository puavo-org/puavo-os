class image::bundle::bootstrap_configure {
  include packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive |>

  file {
    '/etc/puavo-image-build/config':
      content => "rule-updates from-filesystem\n";
  }
}
