class veyon {
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_veyon':
      source => 'puppet:///modules/veyon/setup_veyon';
  }
}
