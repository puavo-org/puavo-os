class graphics_stack_hacks::trusty_xorg_intel {
  include graphics_stack_hacks,
          packages

  graphics_stack_hacks::download_alternative_deb {
    'xserver-xorg-input-synaptics_1.7.4':
      file    => 'xserver-xorg-input-synaptics_1.7.4-0ubuntu1_i386.deb',
      urlbase => 'http://mirror.opinsys.fi/pool/main/x/xserver-xorg-input-synaptics';

    'xserver-xorg-video-intel_2.99.910':
      file    => '/xserver-xorg-video-intel_2.99.910-0ubuntu1.6_i386.deb',
      urlbase => 'http://mirror.opinsys.fi/pool/main/x/xserver-xorg-video-intel';
  }

  file {
    '/usr/share/puavo-ltsp/init-puavo.d/93-alternate-xorg-drivers':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/graphics_stack_hacks/93-alternate-xorg-drivers',
  }

  Package <| title == puavo-ltsp-client |>
}
