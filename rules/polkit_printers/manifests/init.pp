class polkit_printers {
  include ::packages

  file {
    '/etc/polkit-1/localauthority/50-local.d/00.printer.settings.pkla':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package['policykit-1'],
      source  => 'puppet:///modules/polkit_printers/00.printer.settings.pkla';
  }

  Package <| title == "policykit-1" |>
}
