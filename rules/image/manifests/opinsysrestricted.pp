class image::opinsysrestricted {
  include ::image::allinone,
          ::oracle_java,
          ::puavo_pkg::packages,
          ::ssh_server

  # Realize all available puavo-pkg packages
  Puavo_pkg::Install <| |>

  # Notes on puavo-pkg distribution in images:
  #
  #   ----------------------------------------------------------------------
  #   ekapeli-alku:
  #     On 21.5.2015, Ville Mönkkönen, on a private email said:
  #
  #     "Voitte toki jaella peliä edelleen käyttäjille, kunhan ette erikseen
  #      pyydä käyttäjiltä rahaa pelin jakelusta."
  #   ----------------------------------------------------------------------
}
