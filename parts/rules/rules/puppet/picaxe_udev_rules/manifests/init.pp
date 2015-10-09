class picaxe_udev_rules {
  file {
    '/etc/udev/rules.d/99-axe027.rules':
      source => 'puppet:///modules/picaxe_udev_rules/99-axe027.rules';
  }
}
