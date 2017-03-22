class backgrounds {
  include ::packages

  $backgrounds_dir = '/usr/share/backgrounds/puavo-greeter/default'

  define background ($package) {
    $background_file = $title

    file {
      "${::backgrounds::backgrounds_dir}/${background_file}":
        ensure  => link,
        require => Package[$package],
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
    'Backyard_Mushrooms_by_Kurt_Zitzelman.jpg':
      package => 'ubuntu-wallpapers-trusty';

    'Beach_by_Renato_Giordanelli.jpg':
      package => 'ubuntu-wallpapers-trusty';

    'Begonia_by_fatpoint21.jpg':
      package => 'ubuntu-wallpapers-raring';

    'Breaker_by_Lyle_Nel.jpg':
      package => 'ubuntu-wallpapers-wily';

    'Brother_typewriter_by_awdean1.jpg':
      package => 'ubuntu-wallpapers-raring';

    'Cedar_Wax_Wing_by_Raymond_Lavoie.jpg':
      package => 'ubuntu-wallpapers-vivid';

    'Early_Blossom_by_Dh0r.jpg':
      package => 'ubuntu-wallpapers-precise';

    'edubuntu-ladybug.jpg':
      package => 'edubuntu-wallpapers';

    'edubuntu-northern-lights.jpg':
      package => 'edubuntu-wallpapers';

    'Empty_Space_by_Glenn_Rayat.jpg':
      package => 'ubuntu-wallpapers-utopic';

    'Forever_by_Shady_S.jpg':
      package => 'ubuntu-wallpapers-trusty';

    'Grass_by_Jeremy_Hill.jpg':
      package => 'ubuntu-wallpapers-saucy';

    'Ibanez_Infinity_by_Jaco_Kok.jpg':
      package => 'ubuntu-wallpapers-trusty';

    'Kronach_leuchtet_2014_by_Brian_Fox.jpg':
      package => 'ubuntu-wallpapers-utopic';

    'Light_my_fire_evening_sun_by_Dariusz_Duma.jpg':
      package => 'ubuntu-wallpapers-wily';

    'Morning_Sun_on_Frost-Covered_Leaves_by_Gary_A_Stafford.jpg':
      package => 'ubuntu-wallpapers-raring';

    'Redes_de_hilo_by_Juan_Pablo_Lauriente.jpg':
      package => 'ubuntu-wallpapers-utopic';

    'Reflections_by_Trenton_Fox.jpg':
      package => 'ubuntu-wallpapers-trusty';

    'Speaker_Weave_by_Phil_Jackson.jpg':
      package => 'ubuntu-wallpapers-precise';

    'Sunny_Autumn_by_Joel_Heaps.jpg':
      package => 'ubuntu-wallpapers-utopic';

    'The_Forbidden_City_by_Daniel_Mathis.jpg':
      package => 'ubuntu-wallpapers-precise';

    'The_Land_of_Edonias_by_Γιωργος_Αργυροπουλος.jpg':
      package => 'ubuntu-wallpapers-xenial';

    'Tie_My_Boat_by_Ray_García.jpg':
      package => 'ubuntu-wallpapers-precise';

    'Tramonto_a_Scalea_by_Renatvs88.jpg':
      package => 'ubuntu-wallpapers-wily';

    'Vanishing_by_James_Wilson.jpg':
      package => 'ubuntu-wallpapers-quantal';

    'Warmlights.jpg':
      package => 'ubuntu-wallpapers-lucid';
  }

  Package <| tag == 'tag_wallpapers' |>
}
