class polkit_printers {
  file {
    '/etc/polkit-1/localauthority/50-local.d/00.printer.settings.pkla':
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/polkit_printers/00.printer.settings.pkla';
  }
}
