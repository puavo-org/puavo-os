class packages::all {
  include packages,
          packages::partner,
          packages::ubuntu

  # install all packages listed in packages
  Package <| |> { ensure => present, }
}
