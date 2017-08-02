class image::opinsys {
  include ::art::opinsys,
          ::image::allinone,
          ::oracle_java,
          ::primus,
          ::puavo_pkg::packages,
          ::ssh_server

  # Realize all available puavo-pkg packages
  Puavo_pkg::Install <| |>

  Package <| tag == 'tag_debian_nonfree' |>
}
