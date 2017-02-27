class fontconfig {
  include ::packages

  exec {
    'configure fonts':
      command     => '/usr/bin/fc-cache && /usr/bin/mkfontscale && /usr/bin/mkfontdir',
      refreshonly => true,
      require     => [ File['/etc/fonts/conf.d/65-fonts-sourcesans.conf']
                     , Package['fontconfig']
                     , Package['xfonts-utils'] ];
  }

  file {
    '/etc/fonts/conf.avail/65-fonts-sourcesans.conf':
      source => 'puppet:///modules/fontconfig/65-fonts-sourcesans.conf';

    '/etc/fonts/conf.d/65-fonts-sourcesans.conf':
      ensure  => link,
      notify  => Exec['configure fonts'],
      require => File['/etc/fonts/conf.avail/65-fonts-sourcesans.conf'],
      target  => '../conf.avail/65-fonts-sourcesans.conf';

    '/etc/fonts/local.conf':
      source  => 'puppet:///modules/fontconfig/local.conf';
  }

  Package <| title == fontconfig
          or title == texlive-fonts-extra
          or title == xfonts-utils |>
}
