class users {
  file {
    '/etc/login.defs':
      source => 'puppet:///modules/users/etc_login.defs';
  }
}
