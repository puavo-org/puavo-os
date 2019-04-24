class backgrounds {
  include ::packages
  include ::backgrounds::thumbs

  $backgrounds_dir = '/usr/share/backgrounds/puavo-greeter/default'

  define background () {
    $background_file = $title

    file {
      "${::backgrounds::backgrounds_dir}/${background_file}":
        ensure  => link,
        require => Puavo_pkg::Install['ubuntu-wallpapers'],
        target  => "../../${background_file}";
    }
  }

  file {
    [ '/usr/share/backgrounds'
    , '/usr/share/backgrounds/puavo-greeter'
    , $backgrounds_dir ]:
      ensure => directory;
  }

  ::backgrounds::background {
    [ 'Backyard_Mushrooms_by_Kurt_Zitzelman.jpg'
    , 'Beach_by_Renato_Giordanelli.jpg'
    , 'Begonia_by_fatpoint21.jpg'
    , 'Breaker_by_Lyle_Nel.jpg'
    , 'Brother_typewriter_by_awdean1.jpg'
    , 'Cedar_Wax_Wing_by_Raymond_Lavoie.jpg'
    , 'Early_Blossom_by_Dh0r.jpg'
    , 'Empty_Space_by_Glenn_Rayat.jpg'
    , 'Forever_by_Shady_S.jpg'
    , 'Grass_by_Jeremy_Hill.jpg'
    , 'Ibanez_Infinity_by_Jaco_Kok.jpg'
    , 'Kronach_leuchtet_2014_by_Brian_Fox.jpg'
    , 'Light_my_fire_evening_sun_by_Dariusz_Duma.jpg'
    , 'Morning_Sun_on_Frost-Covered_Leaves_by_Gary_A_Stafford.jpg'
    , 'Redes_de_hilo_by_Juan_Pablo_Lauriente.jpg'
    , 'Reflections_by_Trenton_Fox.jpg'
    , 'Speaker_Weave_by_Phil_Jackson.jpg'
    , 'Sunny_Autumn_by_Joel_Heaps.jpg'
    , 'The_Forbidden_City_by_Daniel_Mathis.jpg'
    , 'The_Land_of_Edonias_by_Γιωργος_Αργυροπουλος.jpg'
    , 'Tie_My_Boat_by_Ray_García.jpg'
    , 'Tramonto_a_Scalea_by_Renatvs88.jpg'
    , 'Vanishing_by_James_Wilson.jpg'
    , 'Warmlights.jpg' ]: ;
  }

  Puavo_pkg::Install <| title == 'ubuntu-wallpapers' |>
}
