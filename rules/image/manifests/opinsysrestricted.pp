class image::opinsysrestricted {
  include ::image::allinone,
          ::oracle_java,
          ::puavo_pkg::packages,
          ::ssh_server

  # Realize all available puavo-pkg packages
  Puavo_pkg::Install <| |>
}
