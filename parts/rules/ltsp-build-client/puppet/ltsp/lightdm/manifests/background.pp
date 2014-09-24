class lightdm::background {
  include packages

  file {
    '/usr/share/backgrounds/puavo-greeter':
      ensure => directory;

    '/usr/share/backgrounds/puavo-greeter/Beach_by_Renato_Giordanelli.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-trusty'],
      target => '../Beach_by_Renato_Giordanelli.jpg';

    '/usr/share/backgrounds/puavo-greeter/Cairn_by_Sylvain_Naudin.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-quantal'],
      target => '../Cairn_by_Sylvain_Naudin.jpg';

    '/usr/share/backgrounds/puavo-greeter/Early_Morning_by_Robert_Katzki.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-quantal'],
      target => '../Early_Morning_by_Robert_Katzki.jpg';

    '/usr/share/backgrounds/puavo-greeter/Fleurs_de_Prunus_24_by_Jérôme_Boivin.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-raring'],
      target => '../Fleurs_de_Prunus_24_by_Jérôme_Boivin.jpg';

    '/usr/share/backgrounds/puavo-greeter/Ibanez_Infinity_by_Jaco_Kok.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-trusty'],
      target => '../Ibanez_Infinity_by_Jaco_Kok.jpg';

    '/usr/share/backgrounds/puavo-greeter/Morning_Sun_on_Frost-Covered_Leaves_by_Gary_A_Stafford.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-raring'],
      target => '../Morning_Sun_on_Frost-Covered_Leaves_by_Gary_A_Stafford.jpg';

    '/usr/share/backgrounds/puavo-greeter/Nylon_Rainbow_by_Sam_Hewitt.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-saucy'],
      target => '../Nylon_Rainbow_by_Sam_Hewitt.jpg';

    '/usr/share/backgrounds/puavo-greeter/Pantano_de_Orellana_by_mgarciaiz.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-quantal'],
      target => '../Pantano_de_Orellana_by_mgarciaiz.jpg';

    '/usr/share/backgrounds/puavo-greeter/Partitura_by_Vincijun.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-trusty'],
      target => '../Partitura_by_Vincijun.jpg';

    '/usr/share/backgrounds/puavo-greeter/Speaker_Weave_by_Phil_Jackson.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-precise'],
      target => '../Speaker_Weave_by_Phil_Jackson.jpg';

    '/usr/share/backgrounds/puavo-greeter/Tie_My_Boat_by_Ray_García.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-precise'],
      target => '../Tie_My_Boat_by_Ray_García.jpg';

    '/usr/share/backgrounds/puavo-greeter/Vanishing_by_James_Wilson.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-quantal'],
      target => '../Vanishing_by_James_Wilson.jpg';

    '/usr/share/backgrounds/puavo-greeter/Winter_Morning_by_Shannon_Lucas.jpg':
      ensure => link,
      require => Package['ubuntu-wallpapers-precise'],
      target => '../Winter_Morning_by_Shannon_Lucas.jpg';
  }

  Package <| title == ubuntu-wallpapers-precise
  or title == ubuntu-wallpapers-quantal
  or title == ubuntu-wallpapers-raring
  or title == ubuntu-wallpapers-saucy
  or title == ubuntu-wallpapers-trusty |>

}
