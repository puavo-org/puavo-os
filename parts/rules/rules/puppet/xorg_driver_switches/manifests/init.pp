class xorg_driver_switches {
  include packages

  $altdebdir = '/var/opt/altdebs'

  define download_alternative_deb ($file, $urlbase) {
    $targetpath = "${xorg_driver_switches::altdebdir}/${file}"
    $url        = "${urlbase}/${file}"

    exec {
      "download $title":
        command => "/usr/bin/wget -O ${targetpath}.tmp ${url} && /bin/mv ${targetpath}.tmp ${targetpath}",
        creates => $targetpath,
        require => Package['wget'];
    }
  }

  download_alternative_deb {
    'xserver-xorg-input-synaptics_1.7.4':
      file    => 'xserver-xorg-input-synaptics_1.7.4-0ubuntu1_i386.deb',
      urlbase => 'http://mirror.opinsys.fi/pool/main/x/xserver-xorg-input-synaptics';

    'xserver-xorg-video-intel_2.99.910':
      file    => '/xserver-xorg-video-intel_2.99.910-0ubuntu1.6_i386.deb',
      urlbase => 'http://mirror.opinsys.fi/pool/main/x/xserver-xorg-video-intel';
  }

  file {
    $altdebdir:
      ensure => directory;

    '/usr/share/puavo-ltsp/init-puavo.d/93-alternate-xorg-drivers':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/xorg_driver_switches/93-alternate-xorg-drivers',
  }

  Package <| title == puavo-ltsp-client or title == wget |>
}
