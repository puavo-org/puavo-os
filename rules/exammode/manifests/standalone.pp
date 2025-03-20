class exammode::standalone {
  include ::exammode

  file {
    "${exammode::puavo_exammode_dir}/session.json":
      require => User['puavo-examuser'],
      source => 'puppet:///modules/exammode/standalone_session.json';
  }
}
