class image::builder {
  include image::bundle::basic,
	  packages

  Apt::Key        <| title == "opinsys-repo.gpgkey" |>
  Apt::Repository <| title == archive
                  or title == kernels
                  or title == proposed
                  or title == repo |>

  Package <| tag == 'tag_admin'
          or tag == 'tag_basic'
          or title == puavo-devscripts
          or title == puavo-image-tools |>
}
