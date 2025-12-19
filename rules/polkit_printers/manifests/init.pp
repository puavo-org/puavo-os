class polkit_printers {
  include ::packages

  file {
    '/etc/polkit-1/rules.d/90-allow-users-to-change-printers.rules':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package['polkitd'],
      source  => 'puppet:///modules/polkit_printers/90-allow-users-to-change-printers.rules';
  }

  Package <| title == "polkitd" |>
}
