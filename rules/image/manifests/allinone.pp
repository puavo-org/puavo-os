class image::allinone {
  include ::image::bundle::allinone

  ::plymouth::set_default_theme { 'kites': ; }
}
