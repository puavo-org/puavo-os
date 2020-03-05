class exec_restrictions {
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_exec_restrictions':
      source => 'puppet:///modules/exec_restrictions/setup_exec_restrictions';
  }
}
