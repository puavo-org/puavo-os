class image::bundle::bootserver {
  include ::packages

  Package <| tag == tag_puavo_bootserver |>
}
