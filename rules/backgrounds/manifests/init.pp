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
    [ '163_by_e4v.jpg'
    , 'Brother_typewriter_by_awdean1.jpg'
    , 'Candy_by_Bernhard_Hanakam.jpg'
    , 'Classic_Guitar_Detail_by_Sten_Jørgen_Pettersen.jpg'
    , 'Cyclotron_by_cyclotron_beam.jpg'
    , 'Floorboards_by_Dawid_Huczyński.jpg'
    , 'Forest_by_Moritz_Reisinger.jpg'
    , 'Forever_by_Shady_S.jpg'
    , 'Haukland_Beach_view_by_Michele_Agostini.jpg'
    , 'H_by_Manuel_Sagredo.jpg'
    , 'IMG_7632_by_Jobin_Babu.jpg'
    , 'Kronach_leuchtet_2014_by_Brian_Fox.jpg'
    , 'larung_gar_by_night_by_Geza_Radics.jpg'
    , 'Moss_inflorescence_by_carmelo75.jpg'
    , 'Mr._Tau_and_The_Tree_-_by_TJ.jpg'
    , 'Mushrooms_3_by_moritzmhmk.jpg'
    , 'Music_by_tomasino.cz.jpg'
    , 'Night_lights_by_Alberto_Salvia_Novella.jpg'
    , 'Redes_de_hilo_by_Juan_Pablo_Lauriente.jpg'
    , 'Reflections_by_Trenton_Fox.jpg'
    , 'Sea_Fury_by_Ian_Worrall.jpg'
    , 'Some_Light_Reading_by_Brandilyn_Carpenter.jpg'
    , 'TCP118v1_by_Tiziano_Consonni.jpg'
    , 'Tenerife_Roques_de_Anaga_by_Frederik_Schulz.jpg'
    , 'Tesla_by_Tomasino.cz.jpg'
    , 'Trazo_solitario_by_Julio_Diliegros.jpg'
    , 'ubuntu16_10_by_Khoir_Rudin.png'
    , 'Wanaka_Tree_by_Stephane_Pakula.jpg'
    , 'Winter_Fog_by_Daniel_Vesterskov.jpg'
    , 'Yala_mountain_by_Geza_Radics.jpg'
    , 'Flocking_by_noombox.jpg' ]: ;
  }

  Puavo_pkg::Install <| title == 'ubuntu-wallpapers' |>
}
