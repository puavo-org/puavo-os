class packages::ubuntu {
  include packages

  # install all ubuntu packages listed in packages
  Package <| tag == "ubuntu" |> { ensure => present, }
}
