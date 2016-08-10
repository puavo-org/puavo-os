class image::basic {
  include image::bundle::basic,
	  packages

  Package <| tag == basic |>

}
