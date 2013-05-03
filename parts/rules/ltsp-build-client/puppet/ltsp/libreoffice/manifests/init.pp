class libreoffice {

  file {
    '/usr/lib/libreoffice/share/registry/calc.xcd':
      content => template('libreoffice/calc.xcd'),
      require => Package['libreoffice-calc'];

    '/usr/lib/libreoffice/share/registry/impress.xcd':
      content => template('libreoffice/impress.xcd'),
      require => Package['libreoffice-impress'];

    '/usr/lib/libreoffice/share/registry/writer.xcd':
      content => template('libreoffice/writer.xcd'),
      require => Package['libreoffice-writer'];
  }

}
