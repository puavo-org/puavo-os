class image::exam {
  include ::kernels
  include ::packages

  # XXX This list could be made smaller, "tag_puavo" includes many
  # XXX packages not needed for this.
  Package <|
       tag   == 'tag_kernel'
    or tag   == 'tag_puavo'
    or title == 'plocate'
  |>
}
