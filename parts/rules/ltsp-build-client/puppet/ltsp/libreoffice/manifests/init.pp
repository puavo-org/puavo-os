class libreoffice {
  require packages
  include libreoffice::config

  # Set libreoffice default formats to MS Office formats (yack!).

  dpkg::divert {
    '/usr/lib/libreoffice/share/registry/calc.xcd':
      before => File['/usr/lib/libreoffice/share/registry/calc.xcd'],
      dest   => '/usr/lib/libreoffice/share/registry/calc.xcd.distrib';

    '/usr/lib/libreoffice/share/registry/impress.xcd':
      before => File['/usr/lib/libreoffice/share/registry/impress.xcd'],
      dest   => '/usr/lib/libreoffice/share/registry/impress.xcd.distrib';

    '/usr/lib/libreoffice/share/registry/print.xcd':
      before => File['/usr/lib/libreoffice/share/registry/print.xcd'],
      dest   => '/usr/lib/libreoffice/share/registry/print.xcd.distrib';

    '/usr/lib/libreoffice/share/registry/writer.xcd':
      before => File['/usr/lib/libreoffice/share/registry/writer.xcd'],
      dest   => '/usr/lib/libreoffice/share/registry/writer.xcd.distrib';
  }

  file {
    '/usr/lib/libreoffice/share/registry/calc.xcd':
      source => 'puppet:///modules/libreoffice/calc.xcd';

    '/usr/lib/libreoffice/share/registry/impress.xcd':
      source => 'puppet:///modules/libreoffice/impress.xcd';

    # Use Gnome print dialog
    '/usr/lib/libreoffice/share/registry/print.xcd':
      source => 'puppet:///modules/libreoffice/print.xcd';

    '/usr/lib/libreoffice/share/registry/writer.xcd':
      source => 'puppet:///modules/libreoffice/writer.xcd';
  }

  Package <| title == libreoffice-calc
          or title == libreoffice-impress
          or title == libreoffice-writer |>
}
