class xorg::keyboard_layouts {
  include ::dpkg
  include ::packages

  $xkb_dir = '/usr/share/X11/xkb'

  dpkg::simpledivert {
    [ "${xkb_dir}/rules/evdev.xml"
    , "${xkb_dir}/symbols/fi"
    , "${xkb_dir}/symbols/ru" ]: ;
  }

  file {
    "${xkb_dir}/rules/evdev.xml":
      require => [ Dpkg::Simpledivert["${xkb_dir}/rules/evdev.xml"]
                 , Package['xkb-data'] ],
      source  => 'puppet:///modules/xorg/xkb/rules/evdev.xml';

    "${xkb_dir}/symbols/fi":
      require => [ Dpkg::Simpledivert["${xkb_dir}/symbols/fi"]
                 , Package['xkb-data'] ],
      source  => 'puppet:///modules/xorg/xkb/symbols/fi';

    "${xkb_dir}/symbols/ru":
      require => [ Dpkg::Simpledivert["${xkb_dir}/symbols/fi"]
                 , Package['xkb-data'] ],
      source  => 'puppet:///modules/xorg/xkb/symbols/ru';
  }

  Package <| title == 'xkb-data' |>
}
