class wine::use_wine_devel_as_default {
  include ::packages

  exec {
    'set wine-devel as the default Wine':
      command => '/usr/bin/update-alternatives --set wine /usr/bin/wine-development',
      require => [ Package['wine-development']
                 , Package['wine32-development']
                 , Package['wine64-development'] ],
      unless  => "/usr/bin/update-alternatives --query wine | /bin/grep -qx 'Value: /usr/bin/wine-development'";
  }

  Package <| title == 'wine-development'
          or title == 'wine32-development'
          or title == 'wine64-development' |>
}
