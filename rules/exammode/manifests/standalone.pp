class exammode::standalone {
  include ::exammode
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_examhost_session':
      source => 'puppet:///modules/exammode/setup_examhost_session';
  }
}
