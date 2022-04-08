class backgrounds {
  include ::packages
  include ::backgrounds::thumbs

  $backgrounds_dir = '/usr/share/backgrounds/puavo-greeter-default-random'

  define background () {
    $background_file = $title

    file {
      "${::backgrounds::backgrounds_dir}/${background_file}":
        ensure  => link,
        require => Puavo_pkg::Install['ubuntu-wallpapers-bullseye'],
        target  => "../${background_file}";
    }
  }

  file {
    '/etc/X11/Xsession.d/72puavo-ensure-desktop-background':
      source => 'puppet:///modules/backgrounds/72puavo-ensure-desktop-background';

    [ '/usr/share/backgrounds', $backgrounds_dir ]:
      ensure => directory;
  }

  ::backgrounds::background {
    [ 'brad-huchteman-stone-mountain.jpg'
    , 'Crocus_Wallpaper_by_Roy_Tanck.jpg'
    , 'Foggy_Forest_by_Jake_Stewart.jpg'
    , 'Forever_by_Shady_S.jpg'
    , 'Jelly_Fish_by_RaDu_GaLaN.jpg'
    , 'H_by_Manuel_Sagredo.jpg'
    , 'Night_lights_by_Alberto_Salvia_Novella.jpg'
    , 'On_top_of_the_Rubihorn_by_Matthias_Niess.jpg'
    , 'Raindrops_On_The_Table_by_Alex_Fazit.jpg'
    , 'Reflections_by_Trenton_Fox.jpg'
    , 'Silver_Back_Gorilla_by_Mike_Arney.jpg'
    , 'TCP118v1_by_Tiziano_Consonni.jpg'
    , 'Wall_with_door_on_Gozo_by_Matthias_Niess.jpg' ]: ;
  }

  Puavo_pkg::Install <| title == 'ubuntu-wallpapers-bullseye' |>
}
